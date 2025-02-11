defmodule JSV.Resolver.Local do
  defmacro __using__(opts) do
    source_opt =
      case Keyword.fetch(opts, :source) do
        {:ok, q} -> q
        :error -> raise ArgumentError, "the :source option is required when using #{inspect(__MODULE__)}"
      end

    quote bind_quoted: binding() do
      sources = JSV.Resolver.Local.resolve_sources(source_opt)

      @behaviour JSV.Resolver

      @impl true
      def resolve(id, opts)

      Enum.each(sources, fn {id, raw_schema} ->
        def resolve(unquote(id), _opts) do
          {:ok, unquote(Macro.escape(raw_schema))}
        end
      end)

      def resolve(id, _opts) do
        {:error, {:unknown_id, id}}
      end
    end
  end

  def resolve_sources(sources) do
    sources
    |> List.wrap()
    |> Stream.map(&validate_source/1)
    |> Stream.flat_map(&expand_source/1)
    |> Stream.flat_map(&read_source/1)
    |> Stream.flat_map(&decode_source/1)
  end

  defp validate_source(dir_or_file) when is_binary(dir_or_file) do
    if File.exists?(dir_or_file) do
      dir_or_file
    else
      raise ArgumentError, "source does not exist: #{dir_or_file}"
    end
  end

  defp expand_source(dir_or_file) do
    cond do
      File.regular?(dir_or_file) ->
        case Path.extname(dir_or_file) |> dbg() do
          ".json" -> [dir_or_file]
          _ -> []
        end

      File.dir?(dir_or_file) ->
        Path.wildcard("#{dir_or_file}/**/*.json")
    end
  end

  defp read_source(path) do
    case File.read(path) do
      {:ok, contents} ->
        [contents]

      {:error, reason} ->
        IO.warn("could not read file: #{path} got: #{inspect(reason)}")
        []
    end
  end

  defp decode_source(json) do
    case JSV.Codec.decode(json) do
      {:ok, %{"$id" => id} = decoded} ->
        [{id, decoded}]

      {:ok, decoded} when is_map(decoded) ->
        IO.warn("json schema does not have an $id property: #{inspect(json)}")
        []

      {:ok, _} ->
        IO.warn("json schema is not an object: #{inspect(json)}")
        []

      {:error, reason} ->
        IO.warn("could not decode json: #{inspect(json)} got: #{inspect(reason)}")
        []
    end
  end
end
