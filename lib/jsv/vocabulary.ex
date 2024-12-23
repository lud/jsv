defmodule JSV.Vocabulary do
  alias JSV.Builder
  alias JSV.Helpers
  alias JSV.Validator

  @type validators :: term
  @type pair :: {binary | atom, term}
  @type data :: %{optional(binary) => data} | [data] | binary | boolean | number | nil
  @callback init_validators(Keyword.t()) :: validators
  @callback handle_keyword(pair, validators, Builder.t(), raw_schema :: term) ::
              {:ok, validators(), Builder.t()} | :ignore | {:error, term}
  @callback finalize_validators(validators) :: :ignore | validators
  @callback validate(data, validators, vctx :: Validator.t()) :: {:ok, data} | {:error, Validator.t()}
  @callback format_error(atom, %{optional(atom) => term}, data) ::
              String.t() | {String.t(), %{optional(binary | atom) => term}}

  @optional_callbacks format_error: 3

  @doc """
  Returns the priority for applyting this module to the data.

  Lower values (close to zero) will be applied first. You can think "order"
  instead of "priority" but several modules can share the same priority value.

  This can be useful to define vocabularies that depend on other vocabularies.
  For instance, the `unevaluatedProperties` keyword needs "properties",
  "patternProperties", "additionalProperties" and "allOf", "oneOf", "anyOf",
  _etc._ to be ran before itself so it can lookup what has been evaluated.

  Modules shipped in this library have priority of 100, 200, etc. up to 900 so
  you can interleave your own vocabularies. Casting values to non-validable
  terms (such as structs or dates) should be done by vocabularies with a
  priority of 1000 and above.
  """
  @callback priority() :: pos_integer()

  defmacro __using__(opts) do
    priority_callback =
      case Keyword.fetch(opts, :priority) do
        {:ok, n} when is_integer(n) and n > 0 ->
          quote bind_quoted: [n: n] do
            @impl true
            def priority do
              unquote(n)
            end
          end

        :error ->
          []

        {:ok, other} ->
          raise ArgumentError,
                "expected :priority option to be given as a positive integer literal, got: #{inspect(other)}"
      end

    quote do
      import unquote(__MODULE__)
      @behaviour unquote(__MODULE__)
      require JSV.Validator
      unquote(priority_callback)
    end
  end

  @doc false
  defmacro todo_format_error do
    quote unquote: false do
      IO.warn("used todo_format_error")

      def format_error(kind, args, _data) do
        keys = Map.keys(args)

        map_format = [
          "%{",
          Enum.map_intersperse(args, ", ", fn {k, _} -> [Atom.to_string(k), ": ", Atom.to_string(k)] end),
          "}"
        ]

        raise """
        TODO! unimplemented error formatting in #{inspect(__MODULE__)}:
        #{__ENV__.file}

        def format_error(#{inspect(kind)}, #{map_format}, _data) do
          "some message"
        end
        """
      end
    end
  end

  defmacro take_keyword(atom_form, bind_value, bind_acc, bind_builder, bind_raw_schema, [{:do, block}])
           when is_atom(atom_form) do
    string_form = Atom.to_string(atom_form)

    {bind_value, when_clause} =
      case bind_value do
        {:when, _, [real_bind, when_clause]} ->
          {real_bind, when_clause}

        _ ->
          {bind_value, true}
      end

    quoted =
      quote generated: true do
        @impl true
        def handle_keyword(
              {unquote(string_form), unquote(bind_value)},
              unquote(bind_acc),
              unquote(bind_builder),
              unquote(bind_raw_schema)
            )
            when unquote(when_clause) do
          unquote(block)
        end

        # We do not support atom keywords right now as we convert all schemas to
        # binary form before building the validators.
        #
        # def handle_keyword({x = unquote(atom_form), value}, acc, builder,
        #   raw_schema) do raise "got #{inspect(x)}"
        #   handle_keyword({unquote(string_form), value}, acc, builder,
        # raw_schema) end
      end

    # tap(quoted, &IO.puts(Macro.to_string(&1)))

    quoted
  end

  defmacro ignore_any_keyword do
    quote do
      @impl true
      def handle_keyword(_, _, _, _) do
        :ignore
      end
    end
  end

  defmacro ignore_keyword(atom_form) when is_atom(atom_form) do
    string_form = Atom.to_string(atom_form)

    quote do
      @impl true
      def handle_keyword({unquote(atom_form), _}, _, _, _) do
        :ignore
      end

      def handle_keyword({unquote(string_form), _}, _, _, _) do
        :ignore
      end
    end
  end

  defmacro consume_keyword(atom_form) when is_atom(atom_form) do
    string_form = Atom.to_string(atom_form)

    quote do
      @impl true
      def handle_keyword({unquote(atom_form), _}, acc, builder, _) do
        {:ok, acc, builder}
      end

      def handle_keyword({unquote(string_form), _}, acc, builder, _) do
        {:ok, acc, builder}
      end
    end
  end

  defmacro pass(ast) do
    case ast do
      {:when, _, _} ->
        raise "unsupported guard"

      {fun_name, _, [match_tuple]} ->
        quote do
          def unquote(fun_name)(unquote(match_tuple), data, vctx) do
            {:ok, data, vctx}
          end
        end
    end
  end

  def take_sub(key, subraw, acc, builder) when is_list(acc) do
    case Builder.build_sub(subraw, builder) do
      {:ok, subvalidators, builder} -> {:ok, [{key, subvalidators} | acc], builder}
      {:error, _} = err -> err
    end
  end

  def take_integer(key, n, acc, builder) when is_list(acc) do
    with {:ok, n} <- force_integer(n) do
      {:ok, [{key, n} | acc], builder}
    end
  end

  defp force_integer(n) when is_integer(n) do
    {:ok, n}
  end

  defp force_integer(n) when is_float(n) do
    if Helpers.fractional_is_zero?(n) do
      {:ok, Helpers.trunc(n)}
    else
      {:error, "not an integer: #{inspect(n)}"}
    end
  end

  defp force_integer(other) do
    {:error, "not an integer: #{inspect(other)}"}
  end

  def take_number(key, n, acc, builder) when is_list(acc) do
    with :ok <- check_number(n) do
      {:ok, [{key, n} | acc], builder}
    end
  end

  defp check_number(n) when is_number(n) do
    :ok
  end

  defp check_number(other) do
    {:error, "not a number: #{inspect(other)}"}
  end
end
