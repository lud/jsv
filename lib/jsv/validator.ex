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

  IO.warn("flip the arguments")
  def validate(data, dialect_or_boolean_schema, vdr)

  def validate(data, %BooleanSchema{} = bs, %__MODULE__{} = vdr) do
    case BooleanSchema.valid?(bs) do
      true -> return(data, vdr)
      false -> {:error, add_error(vdr, boolean_schema_error(vdr, bs, data))}
    end
  end

  def validate(data, {:alias_of, key}, %__MODULE__{} = vdr) do
    with_scope(vdr, key, fn vdr ->
      validate(data, Map.fetch!(vdr.validators, key), vdr)
    end)
  end

  def validate(data, validators, %__MODULE__{} = vdr) do
    do_validate(data, validators, vdr)
  end

  defp with_scope(vdr, sub_key, fun) do
    %{scope: scopes} = vdr

    # Premature optimization that can be removed: skip appending scope if it is
    # the same as the current one.
    case {Key.namespace_of(sub_key), scopes} do
      {same, [same | _]} ->
        fun.(vdr)

      {new_scope, scopes} ->
        case fun.(%__MODULE__{vdr | scope: [new_scope | scopes]}) do
          {:ok, data, vdr} -> {:ok, data, %__MODULE__{vdr | scope: scopes}}
          {:error, vdr} -> {:error, %__MODULE__{vdr | scope: scopes}}
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
  def validate_detach(data, dialect_or_boolean_schema, vdr) do
    %{evaluated: parent_evaluated} = vdr
    # TODO no need to add the parent in the list?
    sub_vdr = %__MODULE__{vdr | evaluated: [%{} | parent_evaluated]}

    case validate(data, dialect_or_boolean_schema, sub_vdr) do
      {:ok, data, new_sub} -> {:ok, data, squash_evaluated(new_sub)}
      {:error, new_sub} -> {:error, squash_evaluated(new_sub)}
    end
  end

  # Executes all validators with the given data, collecting errors on the way,
  # then return either ok or error with all errors.
  defp do_validate(data, %Subschema{} = sub, vdr) do
    %{validators: validators} = sub

    iterate(validators, data, vdr, fn {module, mod_validators}, data, vdr ->
      module.validate(data, mod_validators, vdr)
    end)
  end

  @doc """
  Iteration over an enum, accumulating errors.

  This function is kind of a mix between map and reduce:

  * The callback is called with `item, acc, vdr` for all items in the enum,
    regardless of previously returned values. Returning and error tuple does not
    stop the iteration.
  * When returning `{:ok, value, vdr}`, `value` will be the new accumulator.
  * When returning `{:error, vdr}`, the vale accumulator is not changed, but the
    new returned vdr with errors is carried on.
  * Returning an ok tuple after an error tuple on a previous item does not
    remove the errors from the validator struct, they are carried along.

  The final return value is `{:ok, acc, vdr}` if all calls of the callback
  returned an OK tuple, `{:error, vdr}` otherwise.

  This is useful to call all possible validators for a given piece of data,
  collecting all possible errors without stopping, but still returning an error
  in the end if some error arose.
  """
  def iterate(enum, init, vdr, fun) when is_function(fun, 3) do
    {new_acc, new_vdr} =
      Enum.reduce(enum, {init, vdr}, fn item, {acc, vdr} ->
        res = fun.(item, acc, vdr)

        case res do
          # When returning :ok, the errors may be empty or not, depending on
          # previous iterations.
          {:ok, new_acc, %__MODULE__{} = new_vdr} ->
            {new_acc, new_vdr}

          # When returning :error, an error MUST be set
          {:error, %__MODULE__{errors: [_ | _]} = new_vdr} ->
            {acc, new_vdr}

          other ->
            raise "Invalid return from #{inspect(fun)} called with #{inspect(item)}: #{inspect(other)}"
        end
      end)

    return(new_acc, new_vdr)
  end

  def validate_nested(data, key, subvalidators, vdr) when is_binary(key) when is_integer(key) do
    %__MODULE__{path: path, validators: all_validators, scope: scope, evaluated: evaluated} = vdr
    # We do not carry sub errors so custom validation does not have to check for
    # error presence when iterating with map/reduce (although they should use
    # iterate/4).
    sub_vdr = %__MODULE__{
      path: [key | path],
      errors: [],
      validators: all_validators,
      scope: scope,
      evaluated: [%{} | evaluated]
    }

    case validate(data, subvalidators, sub_vdr) do
      {:ok, data, %__MODULE__{} = sub_vdr} ->
        # There should not be errors in sub at this point ?
        new_vdr = vdr |> add_evaluated(key) |> merge_errors(sub_vdr)
        {:ok, data, new_vdr}

      {:error, %__MODULE__{errors: [_ | _]} = sub_vdr} ->
        {:error, merge_errors(vdr, sub_vdr)}
    end
  end

  def validate_ref(data, ref, vdr) do
    with_scope(vdr, ref, fn vdr ->
      do_validate_ref(data, ref, vdr)
    end)
  end

  defp do_validate_ref(data, ref, vdr) do
    subvalidators = checkout_ref(vdr, ref)

    %__MODULE__{path: path, validators: all_validators, scope: scope, evaluated: evaluated} = vdr
    # TODO separate validator must have its isolated evaluated paths list
    separate_vdr = %__MODULE__{
      path: path,
      errors: [],
      validators: all_validators,
      scope: scope,
      evaluated: evaluated
    }

    case validate(data, subvalidators, separate_vdr) do
      {:ok, data, %__MODULE__{} = separate_vdr} ->
        # There should not be errors in sub at this point ?
        new_vdr = vdr |> merge_evaluated(separate_vdr) |> merge_errors(separate_vdr)
        {:ok, data, new_vdr}

      {:error, %__MODULE__{errors: [_ | _]} = separate_vdr} ->
        {:error, merge_errors(vdr, separate_vdr)}
    end
  end

  defp merge_errors(vdr, sub) do
    %__MODULE__{errors: vdr_errors} = vdr
    %__MODULE__{errors: sub_errors} = sub
    %__MODULE__{vdr | errors: do_merge_errors(vdr_errors, sub_errors)}
  end

  defp do_merge_errors([], sub_errors) do
    sub_errors
  end

  defp do_merge_errors(vdr_errors, []) do
    vdr_errors
  end

  defp do_merge_errors(vdr_errors, sub_errors) do
    # TODO maybe append but for now we will flatten only when rendering/formatting errors
    [vdr_errors, sub_errors]
  end

  defp merge_evaluated(vdr, sub) do
    %__MODULE__{evaluated: [top_vdr | rest_vdr]} = vdr
    %__MODULE__{evaluated: [top_sub | _rest_sub]} = sub
    %__MODULE__{vdr | evaluated: [Map.merge(top_vdr, top_sub) | rest_vdr]}
  end

  defp squash_evaluated(vdr) do
    %{evaluated: [to_squash, old_top | rest]} = vdr
    %__MODULE__{vdr | evaluated: [Map.merge(to_squash, old_top) | rest]}
  end

  def return(data, %__MODULE__{errors: []} = vdr) do
    {:ok, data, vdr}
  end

  def return(_data, %__MODULE__{errors: [_ | _]} = vdr) do
    {:error, vdr}
  end

  def checkout_ref(%{scope: scope} = vdr, {:dynamic_anchor, ns, anchor}) do
    case checkout_dynamic_ref(scope, vdr, anchor) do
      :error -> checkout_ref(vdr, {:anchor, ns, anchor})
      {:ok, v} -> v
    end
  end

  def checkout_ref(%{validators: vds}, vkey) do
    Map.fetch!(vds, vkey)
  end

  defp checkout_dynamic_ref([h | scope], vdr, anchor) do
    # Recursion first as the outermost scope should have priority. If the
    # dynamic ref resolution fails with all outer scopes, then actually try to
    # resolve from this scope.
    with :error <- checkout_dynamic_ref(scope, vdr, anchor) do
      Map.fetch(vdr.validators, {:dynamic_anchor, h, anchor})
    end
  end

  defp checkout_dynamic_ref([], _, _) do
    :error
  end

  def boolean_schema_error(vdr, %BooleanSchema{valid?: false}, data) do
    %Error{kind: :boolean_schema, data: data, path: vdr.path, formatter: nil, args: []}
  end

  defmacro with_error(vdr, kind, data, args) do
    quote bind_quoted: binding() do
      JSV.Validator.__with_error__(__MODULE__, vdr, kind, data, args)
    end
  end

  @doc false
  def __with_error__(module, %__MODULE__{} = vdr, kind, data, args) do
    error = %Error{kind: kind, data: data, path: vdr.path, formatter: module, args: args}
    add_error(vdr, error)
  end

  defp add_error(vdr, error) do
    %__MODULE__{errors: errors} = vdr
    %__MODULE__{vdr | errors: [error | errors]}
  end

  defp add_evaluated(vdr, key) do
    %{evaluated: [current | ev]} = vdr
    current = Map.put(current, key, true)
    %__MODULE__{vdr | evaluated: [current | ev]}
  end

  def list_evaluaded(vdr) do
    %{evaluated: [current | _]} = vdr
    Map.keys(current)
  end

  def format_errors(%__MODULE__{} = vdr) do
    vdr.errors |> :lists.flatten() |> Enum.map(&Error.format/1) |> Enum.sort_by(& &1.at, :desc)
  end
end
