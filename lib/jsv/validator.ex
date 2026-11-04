defmodule JSV.Validator do
  alias JSV
  alias JSV.BooleanSchema
  alias JSV.Builder
  alias JSV.ErrorFormatter
  alias JSV.Key
  alias JSV.Subschema
  alias JSV.ValidationError
  alias JSV.Validator.Error
  alias JSV.Validator.ValidationContext
  alias JSV.Vocabulary

  @moduledoc """
  This is the home of the recursive validation logic.

  The validator is called on the root schema, and may be called by vocabulary
  implementations to validate sub parts of the data built withing each
  vocabulary module.
  """

  import ValidationContext, only: [__cfg: 1, __cfg: 2]

  @compile {:inline,
            subschema_context: 3,
            subschema_context: 4,
            detached_context: 3,
            validate_catch: 4,
            validate_in_catch: 7,
            sub_term_context: 3,
            same_term_context: 2,
            push_scope: 2,
            merge_tracked_casts: 3,
            merge_tracked_evaluated: 3}

  @type context :: %ValidationContext{}
  @type eval_sub_path :: Builder.path_segment() | [Builder.path_segment()]
  @type validators :: %{Key.t() => validator}
  @type validator :: JSV.Subschema.t() | BooleanSchema.t() | {:alias_of, binary}
  @type result :: {:ok, term, context} | {:error, context}

  @doc """
  Returns a new validation context targeting the given entrypoint key in the
  validators map, with the given validation options.

  The two flags enable the tracking machinery for casts and for evaluated
  properties and items. They are computed at build time so schemas that use
  neither feature validate without the tracking overhead.

  When the `:feature_errors` option is `false`, the validation stops at the
  first error and the paths used to report errors are not tracked.
  """
  @spec context(%{Key.t() => validator}, Key.t(), map(), boolean(), boolean()) :: context
  def context(validators, entrypoint, opts, feature_cast, feature_unevaluated) do
    %ValidationContext{
      data_path: [],
      eval_path: key_to_eval_path(entrypoint),
      schema_path: [Key.namespace_of(entrypoint)],
      seen_refs: [],
      scope: [Key.namespace_of(entrypoint)],
      errors: [],
      evaluated: [%{}],
      cast_stack: nil,
      config:
        __cfg(
          validators: validators,
          opts: opts,
          feature_cast: feature_cast,
          feature_unevaluated: feature_unevaluated,
          feature_errors: Map.get(opts, :feature_errors, true)
        )
    }
  end

  defp key_to_eval_path(key) do
    # TODO how to handle anchors here ?
    case key do
      {:pointer, _, arg} -> :lists.reverse(arg)
      _ -> []
    end
  end

  @doc """
  Validate the given data with the given validator. The validator is typically a
  sub-part of a `JSV.Root` struct built with `JSV.build/2` such as a
  `JSV.Subschema` struct.
  """
  @spec validate(term, validator(), context) :: result
  def validate(data, subschema, vctx)

  def validate(data, %BooleanSchema{} = bs, vctx) do
    validate_boolean_schema(bs, data, vctx, ErrorFormatter.level_cause())
  end

  def validate(data, {:alias_of, key}, vctx) do
    with_scope(vctx, key, _eval_path = [], fn vctx ->
      validate(data, Map.fetch!(__cfg(vctx.config, :validators), key), vctx)
    end)
  end

  # Executes all validators with the given data, collecting errors on the way,
  # then return either ok or error with all errors.
  #
  # When :feature_cast is false (no cast anywhere in the schema, or the :cast
  # option is disabled), we skip the whole cast stack machinery: nothing will
  # ever be cast, so the push/pop bookkeeping is pure overhead.
  def validate(data, %Subschema{} = sub, %{config: __cfg(feature_cast: true, feature_errors: feature_errors)} = vctx) do
    %{validators: validators, cast: cast} = sub

    # * Set the path of the current validator to he one of the subschema
    # * push the cast of the subschema into the stack. after validation
    vctx = subschema_context(vctx, feature_errors, sub, push_cast(vctx.cast_stack, cast))

    vdr_result = call_vocabulary(validators, data, vctx)

    case vdr_result do
      {:ok, value, vctx} -> pop_apply_cast(value, vctx)
      {:error, _} = err -> err
    end
  end

  def validate(data, %Subschema{} = sub, %{config: __cfg(feature_cast: false, feature_errors: feature_errors)} = vctx) do
    call_vocabulary(sub.validators, data, subschema_context(vctx, feature_errors, sub))
  end

  defp subschema_context(vctx, true = _feature_errors, sub) do
    %{vctx | schema_path: sub.schema_path}
  end

  defp subschema_context(vctx, false = _feature_errors, _sub) do
    vctx
  end

  defp subschema_context(vctx, true = _feature_errors, sub, cast_stack) do
    %{vctx | schema_path: sub.schema_path, cast_stack: cast_stack}
  end

  defp subschema_context(vctx, false = _feature_errors, _sub, cast_stack) do
    %{vctx | cast_stack: cast_stack}
  end

  # Pushing a cast from a subschema is special. Multiple casts can be attempted
  # to be set for the same data path (for instance with allOf) and we cannot
  # support that, so pushes are ignored when a cast is already present.
  #
  # But why do we keep all the nils in the stack? Because we want to apply the
  # casts at the last moment, in the topmost validator for the same data_path.
  #
  # To do so, when pushing a real cast like {module, tag}, the cast is pushed
  # "up" the cast (down to the tail) instead of being the new head:
  #
  # * The validate/3 function call that pushed it will pop a nil in return, and
  #   will not change the data that still needs to be validated by other
  #   keywords/oneOf-scopes/etc.
  # * The topmost validator that pushed a nil will pop the real cast and apply
  #   it after all validations have been done.
  #
  # As the stack can only contain a non-nil value, instead of using a list we
  # use a {level, value} tuple.
  #
  # The context holds a single stack, the one for the current data path. Only
  # validate_sub_term/7 changes the data path: it gives an empty stack to the
  # sub term and returns the parent context, so the parent stack is restored
  # when validating the sub term is done.
  defp push_cast(cast_stack, cast) do
    case cast_stack do
      # If the stack is already defined with nil we increment it and add the
      # cast
      {n, nil} ->
        {n + 1, cast}

      # If the stack is already defined with a cast we increment it and silently
      # ignore the new cast.
      #
      # We ignore it silently because while we had an implementation that could
      # track multiple casts added at the same sublevels, it was warrning false
      # positives too much. We would have to also track if we are in an allOf or
      # if/then vs. oneOf to only warn about actual conflicts.
      {n, existing} ->
        {n + 1, existing}

      # Define a new stack
      nil ->
        {0, cast}
    end
  end

  defp pop_apply_cast(value, vctx) do
    case vctx.cast_stack do
      {0, nil} ->
        {:ok, value, %{vctx | cast_stack: nil}}

      {0, cast} ->
        Vocabulary.Cast.validate(value, cast, %{vctx | cast_stack: nil})

      {n, cast} when n > 0 ->
        {:ok, value, %{vctx | cast_stack: {n - 1, cast}}}
    end
  end

  @doc """
  Reduce over an enum with two accumulators, a user one, and the context.

  * The callback is called with `item, acc, vctx` for all items in the enum,
    regardless of previously returned values. Returning and error tuple does not
    stop the iteration.
  * When returning `{:ok, value, vctx}`, `value` will be the new user
    accumulator, and the new context is carried on.
  * When returning `{:error, vctx}`, the current accumulator is not changed, but
    the new returned context with errors is still carried on.
  * Returning an ok tuple after an error tuple on a previous item does not
    remove the errors from the context struct.

  The final return value is `{:ok, acc, vctx}` if all calls of the callback
  returned an OK tuple, `{:error, vctx}` otherwise.

  This is useful to call all possible validators for a given piece of data,
  collecting all possible errors without stopping, but still returning an error
  in the end if some error arose.
  """
  @spec reduce(Enumerable.t(), term, context, function) :: result
  def reduce(enum, datain, vctx, fun) when is_function(fun, 3) do
    do_reduce(reduce_list(enum), datain, vctx, fun)
  end

  defp reduce_list(list) when is_list(list) do
    list
  end

  defp reduce_list(map) when is_map(map) do
    :maps.to_list(map)
  end

  defp reduce_list(enum) do
    Enum.to_list(enum)
  end

  defp do_reduce([item | rest], data, vctx, fun) do
    case fun.(item, data, vctx) do
      # errors may be empty or not, depending on previous iterations
      {:ok, new_data, new_vctx} ->
        do_reduce(rest, new_data, new_vctx, fun)

      # on :error an error MUST be set; data is unchanged, vctx carries on
      {:error, %ValidationContext{errors: [_ | _]} = new_vctx} ->
        do_reduce(rest, data, new_vctx, fun)

      other ->
        raise "Invalid return from #{Exception.format_fa(fun, 3)}, expected {:ok, data, context} or {:error, term}, got: #{inspect(other)}"
    end
  end

  defp do_reduce([], data, vctx, _fun) do
    return(data, vctx)
  end

  defp call_vocabulary([{mod, mod_validators} | vocab], data, vctx) do
    case mod.validate(data, mod_validators, vctx) do
      {:ok, new_data, new_vctx} ->
        # When returning :ok, the errors may be empty or not, depending on
        # previous iterations.
        call_vocabulary(vocab, new_data, new_vctx)

      # When returning :error, an error MUST be set
      {:error, %ValidationContext{errors: [_ | _]} = new_vctx} ->
        call_vocabulary(vocab, data, new_vctx)

      other ->
        raise "Invalid return from #{Exception.format_mfa(mod, :validate, 3)}, expected {:ok, data, context} or {:error, term}, got: #{inspect(other)}"
    end
  end

  defp call_vocabulary([], data, vctx) do
    return(data, vctx)
  end

  @doc """
  Validate the data with the given validators but separate the current
  evaluation context during the validation.

  Currently evaluated properties or items will not be seen as evaluated during
  the validation by the given `subschema`.
  """
  @spec validate_detach(term, eval_sub_path, validator, context) :: result
  def validate_detach(data, add_eval_path, subschema, %ValidationContext{config: cfg} = vctx) do
    __cfg(feature_errors: feature_errors) = cfg
    validate_catch(data, subschema, detached_context(vctx, cfg, add_eval_path), feature_errors)
  end

  # Same as validate_detach/4 but lets JSV.valid?/2 stop at the first error. Only
  # for keywords that fail whenever one of their subschemas fails.
  @doc false
  @spec __validate_detach_uncaught__(term, eval_sub_path, validator, context) :: result
  def __validate_detach_uncaught__(data, add_eval_path, subschema, %ValidationContext{config: cfg} = vctx) do
    validate(data, subschema, detached_context(vctx, cfg, add_eval_path))
  end

  defp detached_context(vctx, __cfg(feature_errors: false) = cfg, _add_eval_path) do
    case cfg do
      __cfg(feature_unevaluated: false) -> vctx
      _ -> %{vctx | evaluated: [%{}]}
    end
  end

  defp detached_context(vctx, _cfg, add_eval_path) do
    %{eval_path: eval_path, schema_path: schema_path} = vctx

    %{
      vctx
      | evaluated: [%{}],
        errors: [],
        eval_path: append_eval_path(eval_path, add_eval_path),
        schema_path: append_schema_path(schema_path, add_eval_path)
    }
  end

  @doc """
  Validates the data like `validate/3`, but returns an error result instead of
  stopping the whole validation when `JSV.valid?/2` stops at the first error.

  Keywords that do not simply reject the data when a subschema rejects it, like
  `not`, `anyOf` or `contains`, must validate their subschemas with this
  function, `validate_in_catch/6` or `validate_detach/4`.
  """
  @spec validate_catch(term, validator, context) :: result
  def validate_catch(data, subschema, %ValidationContext{config: __cfg(feature_errors: feature_errors)} = vctx) do
    validate_catch(data, subschema, vctx, feature_errors)
  end

  defp validate_catch(data, subschema, vctx, true = _feature_errors) do
    validate(data, subschema, vctx)
  end

  defp validate_catch(data, subschema, vctx, false = _feature_errors) do
    validate(data, subschema, vctx)
  catch
    {__MODULE__, :fail_fast} -> {:error, fail_fast_context(vctx)}
  end

  @doc """
  Validates a sub term of the data like `validate_in/6`, but returns an error
  result instead of stopping the whole validation when `JSV.valid?/2` stops at
  the first error.

  See `validate_catch/3`.
  """
  @spec validate_in_catch(term, Builder.path_segment(), eval_sub_path, validator, context, ErrorFormatter.level()) ::
          result
  def validate_in_catch(
        data,
        key,
        add_eval_path,
        subvalidators,
        vctx,
        boolean_schema_level \\ ErrorFormatter.level_cause()
      )

  def validate_in_catch(
        data,
        key,
        add_eval_path,
        subvalidators,
        %ValidationContext{config: __cfg(feature_errors: feature_errors)} = vctx,
        level
      ) do
    validate_in_catch(data, key, add_eval_path, subvalidators, vctx, level, feature_errors)
  end

  defp validate_in_catch(data, key, add_eval_path, subvalidators, vctx, level, true = _feature_errors) do
    validate_in(data, key, add_eval_path, subvalidators, vctx, level)
  end

  defp validate_in_catch(data, key, add_eval_path, subvalidators, vctx, level, false = _feature_errors) do
    validate_in(data, key, add_eval_path, subvalidators, vctx, level)
  catch
    {__MODULE__, :fail_fast} -> {:error, fail_fast_context(vctx)}
  end

  @doc """
  Validates a sub term of the data, identified by `key`, which can be a property
  name (a string), or an array index (an integer).

  See `validate_as/4` to validate the same data point with a nested keyword. For
  instance `if`, `then` or `else`.

  The `boolean_schema_level` argument sets the level of the error returned when
  `subvalidators` is the `false` schema. Keywords that report their own error
  for the rejected property or item, with a message naming it, should lower it
  to `JSV.ErrorFormatter.level_parent_reported/0`.
  """
  @spec validate_in(term, Builder.path_segment(), eval_sub_path, validator, context, ErrorFormatter.level()) :: result
  def validate_in(data, key, add_eval_path, subvalidators, vctx, boolean_schema_level \\ ErrorFormatter.level_cause())

  def validate_in(data, key, add_eval_path, subvalidators, vctx, boolean_schema_level)
      when is_binary(key)
      when is_integer(key) do
    validate_sub_term(data, key, add_eval_path, subvalidators, vctx, boolean_schema_level, _flag_evaluated? = true)
  end

  @doc """
  Validates a property name of the data, as `validate_in/6` does for property
  values, but without flagging the property as evaluated.

  This is used by the `propertyNames` keyword, which does not evaluate the
  property values and must not affect `unevaluatedProperties`.
  """
  @spec validate_key(binary, eval_sub_path, validator, context, ErrorFormatter.level()) :: result
  def validate_key(key, add_eval_path, subvalidators, vctx, boolean_schema_level \\ ErrorFormatter.level_cause())

  def validate_key(key, add_eval_path, subvalidators, vctx, boolean_schema_level) when is_binary(key) do
    validate_sub_term(key, key, add_eval_path, subvalidators, vctx, boolean_schema_level, _flag_evaluated? = false)
  end

  defp validate_sub_term(data, key, add_eval_path, subvalidators, vctx, boolean_schema_level, flag_evaluated?) do
    sub_vctx = sub_term_context(vctx, key, add_eval_path)

    result =
      case subvalidators do
        %BooleanSchema{} = bs -> validate_boolean_schema(bs, data, sub_vctx, boolean_schema_level)
        _ -> validate(data, subvalidators, sub_vctx)
      end

    case result do
      {:ok, data, sub_vctx} ->
        vctx =
          if flag_evaluated? do
            add_evaluated(vctx, key)
          else
            vctx
          end

        # There should not be errors in sub at this point ?
        new_vctx = merge_errors(vctx, sub_vctx)
        {:ok, data, new_vctx}

      {:error, %ValidationContext{errors: [_ | _]} = sub_vctx} ->
        {:error, merge_errors(vctx, sub_vctx)}
    end
  end

  # A sub term can never be equal to its parent term, seen refs cannot match
  # anymore so we can discard them.
  defp sub_term_context(vctx, key, add_eval_path) do
    %ValidationContext{
      config: cfg,
      data_path: data_path,
      evaluated: evaluated,
      eval_path: eval_path,
      schema_path: schema_path
    } = vctx

    case cfg do
      __cfg(feature_errors: true) ->
        %{
          vctx
          | data_path: [key | data_path],
            eval_path: append_eval_path(eval_path, add_eval_path),
            schema_path: append_schema_path(schema_path, add_eval_path),
            errors: [],
            evaluated: push_evaluated(cfg, evaluated),
            seen_refs: [],
            cast_stack: nil
        }

      __cfg(feature_unevaluated: false) ->
        case vctx do
          %{seen_refs: [], cast_stack: nil} -> vctx
          _ -> %{vctx | seen_refs: [], cast_stack: nil}
        end

      _ ->
        %{vctx | seen_refs: [], cast_stack: nil, evaluated: push_evaluated(cfg, evaluated)}
    end
  end

  @doc """
  Validates data with a sub part of the schema, for instance `if`, `then` or
  `else`. Data path will not change in the context.

  See `validate_in/6` to validate sub terms of the data.
  """
  @spec validate_as(term, eval_sub_path(), validator(), context) :: result
  def validate_as(data, add_eval_path, subvalidators, vctx) do
    sub_vctx = same_term_context(vctx, add_eval_path)

    case validate(data, subvalidators, sub_vctx) do
      {:ok, data, sub_vctx} ->
        # There should not be errors in sub at this point ?
        new_vctx = vctx |> merge_tracked(sub_vctx) |> merge_errors(sub_vctx)
        {:ok, data, new_vctx}

      {:error, %ValidationContext{errors: [_ | _]} = sub_vctx} ->
        {:error, merge_errors(vctx, sub_vctx)}
    end
  end

  # The cast stack is kept as-is: the sub part validates the same data point as
  # its parent, so a cast defined in it belongs to the same stack and must still
  # be applied by the topmost validator for that data path.
  defp same_term_context(vctx, add_eval_path) do
    %ValidationContext{config: cfg, evaluated: evaluated, eval_path: eval_path, schema_path: schema_path} = vctx

    case cfg do
      __cfg(feature_errors: true) ->
        %{
          vctx
          | eval_path: append_eval_path(eval_path, add_eval_path),
            schema_path: append_schema_path(schema_path, add_eval_path),
            errors: [],
            evaluated: push_evaluated(cfg, evaluated)
        }

      __cfg(feature_unevaluated: false) ->
        vctx

      _ ->
        %{vctx | evaluated: push_evaluated(cfg, evaluated)}
    end
  end

  @doc """
  Validates the data against the subschema referenced by the given key.

  A reference that is already being evaluated with the same data is an
  infinite recursion, in that case the data is considered valid, as per JSON
  Schema core 9.4.1.
  """
  @spec validate_ref(term, Key.t(), eval_sub_path(), context) :: result
  def validate_ref(data, ref, eval_path, vctx) do
    %ValidationContext{
      config: cfg,
      seen_refs: seen_refs,
      scope: scopes,
      eval_path: parent_eval_path,
      schema_path: schema_path
    } = vctx

    seen_key = {ref, data}

    # A ref that is already being evaluated with the same data is an infinite
    # recursion (undefined behavior per JSON Schema core 9.4.1). It defines no
    # constraint over the data so it validates successfully.
    if seen_key in seen_refs do
      {:ok, data, vctx}
    else
      ref_scopes = push_scope(scopes, ref)
      add_eval_path = {:ref, eval_path, ref}

      ref_vctx =
        case cfg do
          __cfg(feature_errors: true) ->
            %{
              vctx
              | seen_refs: [seen_key | seen_refs],
                scope: ref_scopes,
                eval_path: append_eval_path(parent_eval_path, add_eval_path),
                schema_path: append_schema_path(schema_path, add_eval_path),
                errors: []
            }

          __cfg(feature_errors: false) ->
            %{vctx | seen_refs: [seen_key | seen_refs], scope: ref_scopes, errors: []}
        end

      subvalidators = checkout_ref(__cfg(cfg, :validators), ref_scopes, ref)

      # The parent context is returned with what the referenced schema tracked,
      # which restores the seen refs, scope and paths at once.
      case validate(data, subvalidators, ref_vctx) do
        {:ok, data, ref_vctx} -> {:ok, data, merge_tracked(vctx, ref_vctx)}
        {:error, ref_vctx} -> {:error, merge_errors(vctx, ref_vctx)}
      end
    end
  end

  defp with_scope(vctx, sub_key, add_eval_path, fun) do
    %ValidationContext{config: cfg, scope: scopes, eval_path: eval_path, schema_path: schema_path} = vctx

    sub_scopes = push_scope(scopes, sub_key)

    scoped_vctx =
      case cfg do
        __cfg(feature_errors: true) ->
          %{
            vctx
            | scope: sub_scopes,
              eval_path: append_eval_path(eval_path, add_eval_path),
              schema_path: append_schema_path(schema_path, add_eval_path)
          }

        __cfg(feature_errors: false) ->
          %{vctx | scope: sub_scopes}
      end

    case fun.(scoped_vctx) do
      {:ok, data, vctx} -> {:ok, data, %{vctx | scope: scopes, eval_path: eval_path}}
      {:error, vctx} -> {:error, %{vctx | scope: scopes, eval_path: eval_path}}
    end
  end

  defp push_scope(scopes, key) do
    case {Key.namespace_of(key), scopes} do
      {same, [same | _]} -> scopes
      {new_scope, scopes} -> [new_scope | scopes]
    end
  end

  defp append_eval_path(eval_path, add_eval_path) when is_list(add_eval_path) do
    :lists.flatten(add_eval_path, eval_path)
  end

  defp append_eval_path(eval_path, segment) do
    [segment | eval_path]
  end

  defp append_schema_path(schema_path, {tag, arg}) when is_atom(arg) when is_integer(arg) when is_binary(arg) do
    [{tag, arg} | schema_path]
  end

  defp append_schema_path(schema_path, arg) when is_atom(arg) when is_integer(arg) when is_binary(arg) do
    [arg | schema_path]
  end

  defp append_schema_path(schema_path, {:ref, _, _}) do
    schema_path
  end

  defp append_schema_path(schema_path, [h | t]) do
    append_schema_path(t, append_schema_path(schema_path, h))
  end

  defp append_schema_path(schema_path, []) do
    schema_path
  end

  defp merge_errors(%ValidationContext{} = vctx, %ValidationContext{errors: []}) do
    vctx
  end

  defp merge_errors(%ValidationContext{} = vctx, %ValidationContext{} = sub) do
    %{errors: vctx_errors} = vctx
    %{errors: sub_errors} = sub
    %{vctx | errors: do_merge_errors(vctx_errors, sub_errors)}
  end

  defp do_merge_errors([], sub_errors) do
    sub_errors
  end

  defp do_merge_errors(vctx_errors, sub_errors) do
    # Errors are not appended. We rather build a deep list. Errors are only
    # flattened at the end of the validation when returning a ValidationError.
    [vctx_errors, sub_errors]
  end

  @doc """
  Merges tracking data from the sub context into the main context. This is
  useful to keep information defined by subschemas for the same data level as
  the parent schema. Such sub schemas are defined with oneOf/allOf/... or $ref.

  Tracking data:

  * Evaluated paths, to work with unevaluated properties/items
  * Cast functions (defschema,defcast)
  """
  @spec merge_tracked(context, context) :: context
  def merge_tracked(%ValidationContext{config: cfg} = vctx, %ValidationContext{} = sub) do
    # Each feature is merged independently and only when active. When neither
    # casts nor unevaluated tracking are used, this is a no-op.
    vctx
    |> merge_tracked_casts(cfg, sub)
    |> merge_tracked_evaluated(cfg, sub)
  end

  defp merge_tracked_casts(vctx, __cfg(feature_cast: true), sub) do
    cast_stack =
      case {vctx.cast_stack, sub.cast_stack} do
        {same, same} -> same
        {{n, nil}, {_, nil}} -> {n, nil}
        {{n, nil}, {_, cast}} -> {n, cast}
      end

    %{vctx | cast_stack: cast_stack}
  end

  defp merge_tracked_casts(vctx, __cfg(feature_cast: false), _sub) do
    vctx
  end

  defp merge_tracked_evaluated(vctx, __cfg(feature_unevaluated: true), sub) do
    %{evaluated: [top_vctx | rest_vctx]} = vctx
    %{evaluated: [top_sub | _rest_sub]} = sub
    %{vctx | evaluated: [Map.merge(top_vctx, top_sub) | rest_vctx]}
  end

  defp merge_tracked_evaluated(vctx, __cfg(feature_unevaluated: false), _sub) do
    vctx
  end

  @doc """
  Returns the validation result for the given data, as `{:ok, data, vctx}`
  when the context holds no errors, `{:error, vctx}` otherwise.
  """
  @spec return(term, context) :: result
  def return(data, %ValidationContext{errors: []} = vctx) do
    {:ok, data, vctx}
  end

  def return(_data, %ValidationContext{errors: [_ | _]} = vctx) do
    {:error, vctx}
  end

  defp checkout_ref(validators, scopes, {:dynamic_anchor, ns, anchor}) do
    case checkout_dynamic_ref(validators, scopes, anchor) do
      :error -> Map.fetch!(validators, {:anchor, ns, anchor})
      {:ok, v} -> v
    end
  end

  defp checkout_ref(validators, _scopes, vkey) do
    Map.fetch!(validators, vkey)
  end

  defp checkout_dynamic_ref(validators, [h | scopes], anchor) do
    # Recursion first as the outermost scope should have priority. If the
    # dynamic ref resolution fails with all outer scopes, then actually try to
    # resolve from this scope.
    with :error <- checkout_dynamic_ref(validators, scopes, anchor) do
      Map.fetch(validators, {:dynamic_anchor, h, anchor})
    end
  end

  defp checkout_dynamic_ref(_validators, [], _anchor) do
    :error
  end

  defp validate_boolean_schema(%BooleanSchema{} = bs, data, vctx, level) do
    case bs.valid? do
      true -> return(data, vctx)
      false -> {:error, add_error(vctx, boolean_schema_error(vctx, bs, data, level))}
    end
  end

  defp boolean_schema_error(vctx, %BooleanSchema{valid?: false} = bs, data, level) do
    %Error{
      kind: :boolean_schema,
      data: data,
      data_path: vctx.data_path,
      eval_path: vctx.eval_path,
      schema_path: bs.schema_path,
      formatter: __MODULE__,
      args: [level: level]
    }
  end

  @doc """
  Adds an error of the given `kind` to the validation context and returns the
  updated context. The calling module is registered as the error formatter.

  The `args` are a keyword list or map of values used when formatting the
  error message, generally the values extracted from the schema keyword and
  the reason of the failure.
  """
  defmacro with_error(vctx, kind, data, args) do
    quote bind_quoted: binding() do
      JSV.Validator.__with_error__(__MODULE__, vctx, kind, data, args)
    end
  end

  @doc false
  @spec __with_error__(module, context, atom, term, term) :: context
  def __with_error__(_module, %ValidationContext{config: __cfg(feature_errors: false)}, _kind, _data, args)
      when is_list(args) or is_map(args) do
    throw({__MODULE__, :fail_fast})
  end

  def __with_error__(module, vctx, kind, data, args) when is_list(args) or is_map(args) do
    add_error(vctx, new_error(module, vctx, kind, data, args))
  end

  @doc false
  defmacro throw_indeterminate(vctx, kind, data, args) do
    quote bind_quoted: binding() do
      JSV.Validator.__throw_indeterminate__(__MODULE__, vctx, kind, data, args)
    end
  end

  @doc false
  @spec __throw_indeterminate__(module, context, atom, term, term) :: no_return()
  def __throw_indeterminate__(module, vctx, kind, data, args) when is_list(args) or is_map(args) do
    throw({JSV, :indeterminate_result, new_error(module, vctx, kind, data, args)})
  end

  defp new_error(module, vctx, kind, data, args) do
    if [] == vctx.schema_path do
      raise "empty schema path"
    end

    %Error{
      kind: kind,
      data: data,
      data_path: vctx.data_path,
      eval_path: vctx.eval_path,
      schema_path: vctx.schema_path,
      formatter: module,
      args: args
    }
  end

  defp add_error(%ValidationContext{config: __cfg(feature_errors: false)}, _error) do
    throw({__MODULE__, :fail_fast})
  end

  defp add_error(%ValidationContext{} = vctx, error) do
    %ValidationContext{errors: errors} = vctx
    %{vctx | errors: [error | errors]}
  end

  # The error result returned by the catch helpers must carry an error. Nothing
  # reads it, as JSV.valid?/2 does not report errors.
  @fail_fast_error %Error{
    kind: :fail_fast,
    data: nil,
    args: [],
    formatter: __MODULE__,
    data_path: [],
    eval_path: [],
    schema_path: []
  }

  defp fail_fast_context(vctx) do
    %{vctx | errors: [@fail_fast_error]}
  end

  # Pushes a fresh evaluation frame for a nested validation, but only when the
  # schema actually uses unevaluatedProperties/unevaluatedItems. Otherwise the
  # frame would never be read, so we keep the parent list untouched.
  defp push_evaluated(__cfg(feature_unevaluated: true), evaluated) do
    [%{} | evaluated]
  end

  defp push_evaluated(__cfg(feature_unevaluated: false), evaluated) do
    evaluated
  end

  defp add_evaluated(%ValidationContext{config: __cfg(feature_unevaluated: false)} = vctx, _key) do
    vctx
  end

  defp add_evaluated(%ValidationContext{config: __cfg(feature_unevaluated: true)} = vctx, key) do
    %{evaluated: [current | ev]} = vctx
    current = Map.put(current, key, true)
    %{vctx | evaluated: [current | ev]}
  end

  # Only reachable when the schema actually uses unevaluatedProperties/Items, in
  # which case the evaluation frames are tracked. There is intentionally no
  # clause for feature_unevaluated: false.
  @doc """
  Lists the object keys and array indices of the data that were evaluated in
  the current evaluation frame. Used by vocabulary implementations to support
  the `unevaluatedProperties` and `unevaluatedItems` keywords.
  """
  @spec list_evaluaded(context) :: [String.t() | integer()]
  def list_evaluaded(%ValidationContext{config: __cfg(feature_unevaluated: true)} = vctx) do
    %{evaluated: [current | _]} = vctx
    Map.keys(current)
  end

  @doc """
  Returns all errors collected in the context as a flat list.
  """
  @spec flat_errors(context) :: [Error.t()]
  def flat_errors(vctx) do
    :lists.flatten(vctx.errors)
  end

  @doc """
  Builds a `JSV.ValidationError` exception from the errors collected in the
  context.
  """
  @spec to_error(context) :: ValidationError.t()
  def to_error(vctx) do
    ValidationError.of(flat_errors(vctx))
  end

  @doc """
  Returns whether the given context contains errors.
  """
  @spec error?(context) :: boolean
  def error?(vctx) do
    case vctx do
      %ValidationContext{errors: [_ | _]} -> true
      %ValidationContext{errors: []} -> false
    end
  end

  @doc false
  # error formatter implementation for the boolean schema
  @spec format_error(:boolean_schema, term, term) :: map
  def format_error(:boolean_schema, args, _data) do
    %{
      message: "value was rejected from boolean schema: false",
      level: Map.get(args, :level, ErrorFormatter.level_cause())
    }
  end
end
