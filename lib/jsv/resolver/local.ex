defmodule JSV.Resolver.Local do
  defmacro __using__(opts) do
    source_opt =
      case Keyword.fetch(opts, :source) do
        {:ok, q} -> q
        :error -> raise ArgumentError, "the :source option is required when using #{inspect(__MODULE__)}"
      end

    warn? =
      case Keyword.fetch(opts, :warn) do
        {:ok, q} -> !!q
        :error -> true
      end

    quote bind_quoted: binding() do
      {:current_stacktrace, [_ | warn_stack]} = Process.info(self(), :current_stacktrace)
      sources = JSV.Resolver.Local.resolve_sources(source_opt, %{stacktrace: warn_stack, warn?: warn?})

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

  def resolve_sources(sources, cfg) do
    sources
    |> List.wrap()
    |> Stream.map(&validate_source/1)
    |> Stream.flat_map(&expand_source(&1, cfg))
    |> Stream.flat_map(&read_source(&1, cfg))
    |> Stream.flat_map(&decode_source(&1, cfg))
  end

  defp validate_source(dir_or_file) when is_binary(dir_or_file) do
    if File.exists?(dir_or_file) do
      dir_or_file
    else
      raise ArgumentError, "source does not exist: #{dir_or_file}"
    end
  end

  defp expand_source(dir_or_file, _) do
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

  defp read_source(path, cfg) do
    case File.read(path) do
      {:ok, contents} ->
        [{path, contents}]

      {:error, reason} ->
        cfg.warn? && IO.warn("could not read file: #{path} got: #{inspect(reason)}", cfg.stacktrace)
        []
    end
  end

  defp decode_source({path, json}, cfg) do
    case JSV.Codec.decode(json) do
      {:ok, %{"$id" => id} = decoded} ->
        [{id, decoded}]

      {:ok, decoded} when is_map(decoded) ->
        cfg.warn? && IO.warn("json schema at #{path} does not have $id", cfg.stacktrace)
        []

      {:ok, _} ->
        cfg.warn? && IO.warn("json schema at #{path} is not an object", cfg.stacktrace)
        []

      {:error, reason} ->
        cfg.warn? && IO.warn("could not decode json schema at path #{path}, got: #{inspect(reason)}", cfg.stacktrace)
        []
    end
  end
end
