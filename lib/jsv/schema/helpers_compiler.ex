defmodule JSV.Schema.HelpersCompiler do
  @moduledoc false

  defmacro defpreset(fun, args) do
    props_doc = listify_props_docs(args)

    quote do
      doc_custom =
        case Module.get_attribute(__MODULE__, :doc) do
          {_, text} when is_binary(text) -> "\n\n#{text}"
          _ -> ""
        end

      @doc "Returns a JSON Schema with #{unquote(props_doc)}.#{doc_custom}"
      @doc group: "Schema Presets"
      @spec unquote(fun)(JSV.Schema.attributes() | nil) :: JSV.Schema.schema()
      def unquote(fun)(extra \\ nil) do
        JSV.Schema.combine(extra, unquote(args))
      end
    end
  end

  defmacro defcompose(fun, args) do
    props_doc = listify_props_docs(args)

    quote do
      doc_custom =
        case Module.get_attribute(__MODULE__, :doc) do
          {_, text} when is_binary(text) -> "\n\n#{text}"
          _ -> ""
        end

      @doc "Defines or merges onto a JSON Schema with #{unquote(props_doc)}.#{doc_custom}"
      @spec unquote(fun)(JSV.Schema.merge_base()) :: JSV.Schema.schema()
      def unquote(fun)(merge_base \\ nil) do
        JSV.Schema.merge(merge_base, unquote(args))
      end
    end
  end

  defp listify_props_docs(props) do
    props
    |> Enum.map(fn {k, v} -> "`#{k}: #{Macro.to_string(v)}`" end)
    |> :lists.reverse()
    |> case do
      [last | [_ | _] = prev] ->
        prev
        |> Enum.intersperse(", ")
        |> :lists.reverse([" and ", last])

      [single] ->
        [single]
    end
  end
end
