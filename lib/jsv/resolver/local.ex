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

    quote bind_quoted: binding(), location: :keep do
      {:current_stacktrace, [_ | warn_stack]} = Process.info(self(), :current_stacktrace)

      cfg = %{stacktrace: warn_stack, warn?: warn?}
      expanded_sources = JSV.Resolver.Local.expand_sources(source_opt, cfg)
      schemas_sources = JSV.Resolver.Local.read_sources(expanded_sources, cfg)

      @__jsv_resolverinitial_source_opt source_opt
      @__jsv_resolver_mtime_index JSV.Resolver.Local.sources_hashes(expanded_sources)

      @behaviour JSV.Resolver

      @impl true
      def resolve(id, opts)

      Enum.each(schemas_sources, fn {id, raw_schema} ->
        def resolve(unquote(id), _opts) do
          {:ok, unquote(Macro.escape(raw_schema))}
        end
      end)

      def resolve(id, _opts) do
        {:error, {:unknown_id, id}}
      end

      ids_list = Enum.map(schemas_sources, fn {id, _} -> id end)

      def resolvable_ids do
        unquote(ids_list)
      end

      def __mix_recompile__? do
        cfg = %{stacktrace: [], warn?: false}

        current_index =
          @__jsv_resolverinitial_source_opt
          |> JSV.Resolver.Local.expand_sources(cfg)
          |> JSV.Resolver.Local.sources_hashes()

        current_index != @__jsv_resolver_mtime_index
      end
    end
  end

  @doc false
  @spec expand_sources(binary | [binary], map) :: [binary]
  def expand_sources(sources, cfg) do
    sources
    |> List.wrap()
    |> Enum.filter(&valid_source?(&1, cfg))
    |> Enum.flat_map(&expand_source(&1, cfg))
  end

  @doc false
  @spec read_sources([binary], map) :: %{binary() => binary()}
  def read_sources(expanded_sources, cfg) do
    expanded_sources
    |> Enum.flat_map(&read_source(&1, cfg))
    |> Enum.flat_map(&decode_source(&1, cfg))
  end

  @doc false
  @spec sources_hashes([binary]) :: %{binary() => {integer(), integer()}}
  def sources_hashes(expanded_sources) do
    Map.new(expanded_sources, fn path ->
      stat = File.stat!(path, time: :posix)
      time = max(stat.mtime, stat.ctime)
      {path, {time, stat.size}}
    end)
  end

  defp valid_source?(dir_or_file, cfg) when is_binary(dir_or_file) do
    if File.exists?(dir_or_file) do
      true
    else
      cfg.warn? && IO.warn("source not found: #{dir_or_file}", cfg.stacktrace)
      false
    end
  end

  defp expand_source(dir_or_file, _) do
    cond do
      File.regular?(dir_or_file) ->
        case Path.extname(dir_or_file) do
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
