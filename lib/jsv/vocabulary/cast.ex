defmodule JSV.Vocabulary.Cast do
  alias JSV.Builder
  alias JSV.Helpers.StringExt
  alias JSV.Validator

  use JSV.Vocabulary,
    # Priority is meaningless here as this vocabulary is handled by the library
    # core. But it takes precedences over all other vocabularies when registering
    # a cast during validation, so we mark it as zero.
    priority: :internal

  @moduledoc false

  @impl true
  def init_validators([]) do
    %{}
  end

  @enforce_keys [:capture, :module, :function, :arity, :cast_args, :all_args]
  defstruct @enforce_keys

  @type t :: %__MODULE__{}

  take_keyword :"jsv-cast",
               [module_str | [tag | _] = rest_args] when is_binary(tag) when is_integer(tag),
               vds,
               builder,
               _ do
    cast = build_cast([module_str | rest_args], builder)

    {put_vd(vds, :"jsv-cast", cast, builder), builder}
  end

  defmodule CastHandlerLocationError do
    defexception [:module, :function, :message]
  end

  defmodule BadCastReturnValueError do
    @enforce_keys [:module, :function, :arity, :value, :expected]
    defexception @enforce_keys

    @spec message(Exception.t()) :: binary
    def message(t) do
      %{module: module, function: fun, arity: arity, value: value, expected: hint} = t
      "bad return from " <> Exception.format_mfa(module, fun, arity) <> ", expected #{hint}, got: #{inspect(value)}"
    end
  end

  defp find_arity!(module, fun) do
    # module should already be loaded from safe_string_to_existing_module
    found = Enum.find(3..1//-1, fn arity -> function_exported?(module, fun, arity) end)

    case found do
      nil ->
        raise CastHandlerLocationError,
          module: module,
          function: fun,
          message: "could not find cast handler #{inspect(module)}.#{fun}/{1..3}"

      arity ->
        arity
    end
  end

  defp verify_arity!(module, fun, arity) do
    # module should already be loaded from safe_string_to_existing_module
    if function_exported?(module, fun, arity) do
      arity
    else
      raise CastHandlerLocationError,
        module: module,
        function: fun,
        message: "could not find cast handler #{inspect(module)}.#{fun}/{1..3}"
    end
  end

  take_keyword :"x-jsv-cast", casts, vds, builder, _ do
    casts = unwrap_ok(normalize_casts(casts, []))
    casts = Enum.map(casts, &build_cast(&1, builder))
    {put_vd(vds, :"x-jsv-cast", casts, builder), builder}
  end

  ignore_any_keyword()

  defp normalize_casts(string, []) when is_binary(string) do
    {:ok, [[string]]}
  end

  defp normalize_casts([[mod | _] = cast | rest], acc) when is_binary(mod) do
    normalize_casts(rest, [cast | acc])
  end

  defp normalize_casts([mod | rest], acc) when is_binary(mod) do
    normalize_casts(rest, [[mod] | acc])
  end

  defp normalize_casts([other | _], _acc) do
    {:error, {:malformed_cast, other}}
  end

  defp normalize_casts([], acc) do
    {:ok, :lists.reverse(acc)}
  end

  defp build_cast([module_str | args], builder) do
    module = unwrap_ok(StringExt.safe_string_to_existing_module(module_str))

    try do
      {fun, arity, cast_args} =
        case module.__jsv__({:cast, args}) do
          {^module, fun, nil = _unknown_arity, cast_args} -> {fun, find_arity!(module, fun), cast_args}
          {^module, fun, arity, cast_args} -> {fun, verify_arity!(module, fun, arity), cast_args}
          {^module, fun, arity} when arity in 1..3 -> {fun, verify_arity!(module, fun, arity), args}
          {^module, fun} -> {fun, find_arity!(module, fun), args}
        end

      _cast = %__MODULE__{
        capture: Function.capture(module, fun, arity),
        module: module,
        function: fun,
        arity: arity,
        cast_args: cast_args,
        all_args: args
      }
    rescue
      [CastHandlerLocationError] ->
        Builder.fail(builder, {:invalid_cast, [module_str | args], module}, :"jsv-cast")

      e in [UndefinedFunctionError, FunctionClauseError] ->
        stack = __STACKTRACE__
        # TODO add full error to builder
        # log_test_error(e, stack)

        case e do
          %{module: ^module, function: :__jsv__} ->
            Builder.fail(builder, {:invalid_cast, [module_str | args], e}, :"jsv-cast")

          _ ->
            reraise e, stack
        end
    end
  end

  defp put_vd(vds, k, v, _builder) when map_size(vds) == 0 do
    Map.put(vds, k, v)
  end

  defp put_vd(_vds, k, _v, builder) do
    Builder.fail(builder, :mixed_casts, k)
  end

  @impl true
  def finalize_validators(map) do
    case map_size(map) do
      0 -> :ignore
      1 -> map
    end
  end

  @impl true
  def validate(data, %{"jsv-cast": call}, vctx) do
    cond do
      Validator.error?(vctx) ->
        {:ok, data, vctx}

      vctx.opts[:cast] ->
        call_cast_rescue(:"jsv-cast", call, data, vctx)

      :other ->
        {:ok, data, vctx}
    end
  end

  def validate(data, %{"x-jsv-cast": casts}, vctx) do
    cond do
      Validator.error?(vctx) ->
        {:ok, data, vctx}

      vctx.opts[:cast] ->
        call_casts(casts, data, vctx)

      :other ->
        {:ok, data, vctx}
    end
  end

  defp call_casts([cast | rest], data, vctx) do
    case call_cast_rescue(:"x-jsv-cast", cast, data, vctx) do
      {:ok, new_data, vctx} -> call_casts(rest, new_data, vctx)
      {:error, _} = error -> error
    end
  end

  defp call_casts([], data, vctx) do
    {:ok, data, vctx}
  end

  defp call_cast_rescue(keyword, %{module: module, function: fun, arity: arity} = cast, data, vctx) do
    case call_cast(cast, arity, data, vctx) do
      {:ok, new_data} ->
        {:ok, new_data, vctx}

      {:error, reason} ->
        {:error,
         JSV.Validator.__with_error__(__MODULE__, vctx, keyword, data,
           cast: cast,
           reason: reason
         )}

      other ->
        raise bad_return_error(cast, other)
    end
  rescue
    e in BadCastReturnValueError ->
      # log_test_error(e, __STACKTRACE__)
      {:error,
       JSV.Validator.__with_error__(__MODULE__, vctx, :"bad-cast-return", data,
         cast: cast,
         reason: e
       )}

    e in [UndefinedFunctionError, FunctionClauseError] ->
      stack = __STACKTRACE__
      # log_test_error(e, stack)

      case e do
        %{module: ^module, function: ^fun} ->
          {:error,
           JSV.Validator.__with_error__(__MODULE__, vctx, :"bad-cast", data,
             cast: cast,
             reason: e
           )}

        _ ->
          reraise e, stack
      end
  end

  defp bad_return_error(cast, value) do
    %{module: module, function: fun, arity: arity} = cast
    %BadCastReturnValueError{module: module, function: fun, arity: arity, value: value, expected: "result tuple"}
  end

  defp call_cast(%{capture: fun}, 1 = _arity, data, _vctx) do
    fun.(data)
  end

  defp call_cast(%{capture: fun, cast_args: args}, 2 = _arity, data, _vctx) do
    fun.(data, args)
  end

  defp call_cast(%{capture: fun, cast_args: args}, 3 = _arity, data, vctx) do
    fun.(data, args, vctx)
  end

  @doc false
  @spec log_test_error(Exception.t(), Exception.stacktrace()) :: :ok
  if Mix.env() == :test do
    def log_test_error(e, stack) do
      require(Logger)
      Logger.warning(["implementation error in test: ", Exception.format(:error, e, stack)])
    end
  else
    def log_test_error(_e, _stack) do
      :ok
    end
  end

  @impl true
  def format_error(errtag, meta, data) when errtag in [:"jsv-cast", :"x-jsv-cast"] do
    %{module: m, all_args: all_args} = meta.cast

    if function_exported?(m, :format_error, 3) do
      case m.format_error(all_args, meta.reason, data) do
        message when is_binary(message) -> %{kind: :cast, message: message}
        other -> other
      end
    else
      %{kind: :cast, message: "cast failed"}
    end
  end

  def format_error(:"bad-cast", _meta, _data) do
    %{kind: :cast, message: "invalid cast"}
  end

  def format_error(:"bad-cast-return", _meta, _data) do
    %{kind: :cast, message: "bad cast return value"}
  end

  defimpl Inspect do
    import Inspect.Algebra

    Code.ensure_loaded!(Inspect.Algebra)

    if function_exported?(Inspect.Algebra, :to_doc_with_opts, 2) do
      @spec inspect(JSV.Vocabulary.Cast.t(), Inspect.Opts.t()) :: {Inspect.Algebra.t(), Inspect.Opts.t()}
      def inspect(%{capture: capture, cast_args: args}, opts) do
        {doc, opts} = to_doc_with_opts([capture | args], opts)
        {concat(["#JSV.Vocabulary.Cast<", doc, ">"]), opts}
      end
    else
      @spec inspect(JSV.Vocabulary.Cast.t(), Inspect.Opts.t()) :: Inspect.Algebra.t()
      def inspect(%{capture: capture, cast_args: args}, opts) do
        doc = to_doc([capture | args], opts)
        concat(["#JSV.Vocabulary.Cast<", doc, ">"])
      end
    end
  end
end
