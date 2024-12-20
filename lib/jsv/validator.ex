defmodule JSV.Validator.Error do
  @enforce_keys [:kind, :data, :args, :formatter, :path]
  defstruct @enforce_keys

  @opaque t :: %__MODULE__{}

  def format(%__MODULE__{} = error) do
    %__MODULE__{kind: kind, data: data, path: path, formatter: formatter, args: args} = error
    formatter = formatter || __MODULE__
    args_map = Map.new(args)

    {message, detail} =
      case formatter.format_error(kind, args_map, data) do
        message when is_binary(message) -> {message, args_map}
        {message, detail} when is_binary(message) -> {message, detail}
      end

    %{kind: kind, at: :lists.reverse(path), message: message, detail: detail}
  end

  def format_error(:boolean_schema, %{}, _data) do
    "value was rejected due to boolean schema false"
  end
end

defmodule JSV.Validator do
  alias JSV
  alias JSV.BooleanSchema
  alias JSV.Key
  alias JSV.Subschema
  alias JSV.Validator.Error

  # TODO remove `%__MODULE__{}=`

  @enforce_keys [:path, :validators, :scope, :errors, :evaluated]
  defstruct @enforce_keys

  @opaque t :: %__MODULE__{}

  def new(validators, scope) do
    %__MODULE__{
      path: [],
      validators: validators,
      scope: scope,
      errors: [],
      evaluated: [%{}]
    }
  end

  IO.warn("TODO remove matches to %__MODULE__{} everywhere")
  # The validator struct is the 3rd argument to mimic the callback on the
  # vocabulary modules where builder and validators are passed as a context as
  # last argument.
  def validate(data, dialect_or_boolean_schema, vctx)

  def validate(data, %BooleanSchema{} = bs, %__MODULE__{} = vctx) do
    case BooleanSchema.valid?(bs) do
      true -> return(data, vctx)
      false -> {:error, add_error(vctx, boolean_schema_error(vctx, bs, data))}
    end
  end

  def validate(data, {:alias_of, key}, %__MODULE__{} = vctx) do
    with_scope(vctx, key, fn vctx ->
      validate(data, Map.fetch!(vctx.validators, key), vctx)
    end)
  end

  def validate(data, validators, %__MODULE__{} = vctx) do
    do_validate(data, validators, vctx)
  end

  defp with_scope(vctx, sub_key, fun) do
    %{scope: scopes} = vctx

    # Premature optimization that can be removed: skip appending scope if it is
    # the same as the current one.
    case {Key.namespace_of(sub_key), scopes} do
      {same, [same | _]} ->
        fun.(vctx)

      {new_scope, scopes} ->
        case fun.(%__MODULE__{vctx | scope: [new_scope | scopes]}) do
          {:ok, data, vctx} -> {:ok, data, %__MODULE__{vctx | scope: scopes}}
          {:error, vctx} -> {:error, %__MODULE__{vctx | scope: scopes}}
        end
    end
  end

  @doc """
  Validate the data with the given validators but separate the current
  evaluation context during the validation, to squash it afterwards.

  This means that currently evaluated properties or items will not be seen as
  evaluated during the validation (detach), and properties or items evaluated by
  the validators will be added back (squash) to the current scope of the given
  validator struct.
  """
  def validate_detach(data, dialect_or_boolean_schema, vctx) do
    %{evaluated: parent_evaluated} = vctx
    # TODO no need to add the parent in the list?
    sub_vctx = %__MODULE__{vctx | evaluated: [%{} | parent_evaluated]}

    case validate(data, dialect_or_boolean_schema, sub_vctx) do
      {:ok, data, new_sub} -> {:ok, data, squash_evaluated(new_sub)}
      {:error, new_sub} -> {:error, squash_evaluated(new_sub)}
    end
  end

  # Executes all validators with the given data, collecting errors on the way,
  # then return either ok or error with all errors.
  defp do_validate(data, %Subschema{} = sub, vctx) do
    %{validators: validators} = sub

    iterate(validators, data, vctx, fn {module, mod_validators}, data, vctx ->
      module.validate(data, mod_validators, vctx)
    end)
  end

  @doc """
  Iteration over an enum, accumulating errors.

  This function is kind of a mix between map and reduce:

  * The callback is called with `item, acc, vctx` for all items in the enum,
    regardless of previously returned values. Returning and error tuple does not
    stop the iteration.
  * When returning `{:ok, value, vctx}`, `value` will be the new accumulator.
  * When returning `{:error, vctx}`, the vale accumulator is not changed, but the
    new returned vctx with errors is carried on.
  * Returning an ok tuple after an error tuple on a previous item does not
    remove the errors from the validator struct, they are carried along.

  The final return value is `{:ok, acc, vctx}` if all calls of the callback
  returned an OK tuple, `{:error, vctx}` otherwise.

  This is useful to call all possible validators for a given piece of data,
  collecting all possible errors without stopping, but still returning an error
  in the end if some error arose.
  """
  def iterate(enum, init, vctx, fun) when is_function(fun, 3) do
    {new_acc, new_vctx} =
      Enum.reduce(enum, {init, vctx}, fn item, {acc, vctx} ->
        res = fun.(item, acc, vctx)

        case res do
          # When returning :ok, the errors may be empty or not, depending on
          # previous iterations.
          {:ok, new_acc, %__MODULE__{} = new_vctx} ->
            {new_acc, new_vctx}

          # When returning :error, an error MUST be set
          {:error, %__MODULE__{errors: [_ | _]} = new_vctx} ->
            {acc, new_vctx}

          other ->
            raise "Invalid return from #{inspect(fun)} called with #{inspect(item)}: #{inspect(other)}"
        end
      end)

    return(new_acc, new_vctx)
  end

  def validate_nested(data, key, subvalidators, vctx) when is_binary(key) when is_integer(key) do
    %__MODULE__{path: path, validators: all_validators, scope: scope, evaluated: evaluated} = vctx
    # We do not carry sub errors so custom validation does not have to check for
    # error presence when iterating with map/reduce (although they should use
    # iterate/4).
    sub_vctx = %__MODULE__{
      path: [key | path],
      errors: [],
      validators: all_validators,
      scope: scope,
      evaluated: [%{} | evaluated]
    }

    case validate(data, subvalidators, sub_vctx) do
      {:ok, data, %__MODULE__{} = sub_vctx} ->
        # There should not be errors in sub at this point ?
        new_vctx = vctx |> add_evaluated(key) |> merge_errors(sub_vctx)
        {:ok, data, new_vctx}

      {:error, %__MODULE__{errors: [_ | _]} = sub_vctx} ->
        {:error, merge_errors(vctx, sub_vctx)}
    end
  end

  def validate_ref(data, ref, vctx) do
    with_scope(vctx, ref, fn vctx ->
      do_validate_ref(data, ref, vctx)
    end)
  end

  defp do_validate_ref(data, ref, vctx) do
    subvalidators = checkout_ref(vctx, ref)

    %__MODULE__{path: path, validators: all_validators, scope: scope, evaluated: evaluated} = vctx
    # TODO separate validator must have its isolated evaluated paths list
    separate_vctx = %__MODULE__{
      path: path,
      errors: [],
      validators: all_validators,
      scope: scope,
      evaluated: evaluated
    }

    case validate(data, subvalidators, separate_vctx) do
      {:ok, data, %__MODULE__{} = separate_vctx} ->
        # There should not be errors in sub at this point ?
        new_vctx = vctx |> merge_evaluated(separate_vctx) |> merge_errors(separate_vctx)
        {:ok, data, new_vctx}

      {:error, %__MODULE__{errors: [_ | _]} = separate_vctx} ->
        {:error, merge_errors(vctx, separate_vctx)}
    end
  end

  defp merge_errors(vctx, sub) do
    %__MODULE__{errors: vctx_errors} = vctx
    %__MODULE__{errors: sub_errors} = sub
    %__MODULE__{vctx | errors: do_merge_errors(vctx_errors, sub_errors)}
  end

  defp do_merge_errors([], sub_errors) do
    sub_errors
  end

  defp do_merge_errors(vctx_errors, []) do
    vctx_errors
  end

  defp do_merge_errors(vctx_errors, sub_errors) do
    # TODO maybe append but for now we will flatten only when rendering/formatting errors
    [vctx_errors, sub_errors]
  end

  defp merge_evaluated(vctx, sub) do
    %__MODULE__{evaluated: [top_vctx | rest_vctx]} = vctx
    %__MODULE__{evaluated: [top_sub | _rest_sub]} = sub
    %__MODULE__{vctx | evaluated: [Map.merge(top_vctx, top_sub) | rest_vctx]}
  end

  defp squash_evaluated(vctx) do
    %{evaluated: [to_squash, old_top | rest]} = vctx
    %__MODULE__{vctx | evaluated: [Map.merge(to_squash, old_top) | rest]}
  end

  def return(data, %__MODULE__{errors: []} = vctx) do
    {:ok, data, vctx}
  end

  def return(_data, %__MODULE__{errors: [_ | _]} = vctx) do
    {:error, vctx}
  end

  def checkout_ref(%{scope: scope} = vctx, {:dynamic_anchor, ns, anchor}) do
    case checkout_dynamic_ref(scope, vctx, anchor) do
      :error -> checkout_ref(vctx, {:anchor, ns, anchor})
      {:ok, v} -> v
    end
  end

  def checkout_ref(%{validators: vds}, vkey) do
    Map.fetch!(vds, vkey)
  end

  defp checkout_dynamic_ref([h | scope], vctx, anchor) do
    # Recursion first as the outermost scope should have priority. If the
    # dynamic ref resolution fails with all outer scopes, then actually try to
    # resolve from this scope.
    with :error <- checkout_dynamic_ref(scope, vctx, anchor) do
      Map.fetch(vctx.validators, {:dynamic_anchor, h, anchor})
    end
  end

  defp checkout_dynamic_ref([], _, _) do
    :error
  end

  def boolean_schema_error(vctx, %BooleanSchema{valid?: false}, data) do
    %Error{kind: :boolean_schema, data: data, path: vctx.path, formatter: nil, args: []}
  end

  defmacro with_error(vctx, kind, data, args) do
    quote bind_quoted: binding() do
      JSV.Validator.__with_error__(__MODULE__, vctx, kind, data, args)
    end
  end

  @doc false
  def __with_error__(module, %__MODULE__{} = vctx, kind, data, args) do
    error = %Error{kind: kind, data: data, path: vctx.path, formatter: module, args: args}
    add_error(vctx, error)
  end

  defp add_error(vctx, error) do
    %__MODULE__{errors: errors} = vctx
    %__MODULE__{vctx | errors: [error | errors]}
  end

  defp add_evaluated(vctx, key) do
    %{evaluated: [current | ev]} = vctx
    current = Map.put(current, key, true)
    %__MODULE__{vctx | evaluated: [current | ev]}
  end

  def list_evaluaded(vctx) do
    %{evaluated: [current | _]} = vctx
    Map.keys(current)
  end

  def format_errors(%__MODULE__{} = vctx) do
    vctx.errors |> :lists.flatten() |> Enum.map(&Error.format/1) |> Enum.sort_by(& &1.at, :desc)
  end
end
