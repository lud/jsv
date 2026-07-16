# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule JSV.TestSuiteGenerator.ValueDumper do
  alias JSV.TestSuiteGenerator.FloatWrapper
  import Inspect.Algebra

  @moduledoc false

  @key_order [
               # metada of the schema
               "$schema",
               "$id",
               "$anchor",
               "$dynamicAnchor",

               # text headers
               "title",
               "description",
               "comment",

               # collection of other schemas
               "definitions",
               "$defs",

               # references to other schemas
               "$dynamicRef",
               "$ref",

               # validations

               # type should be the first validation
               "type",

               # properties should be ordered like so, with required afterwards
               "properties",
               "patternProperties",
               "additionalProperties",
               "required"
             ]
             |> Enum.with_index()
             |> Map.new()

  @schema_struct_keys Map.keys(Map.from_struct(JSV.Schema.__struct__()))

  defstruct value: [], suite_flavor: nil

  def wrap(value, suite_flavor) do
    %__MODULE__{value: value, suite_flavor: suite_flavor}
  end

  def render(%{value: %FloatWrapper{} = fw, suite_flavor: :decimal_test_data}, _) do
    "Decimal.new(#{inspect(fw.float_str)}, JsonSchemaSuite.decimal_opts())"
  end

  def render(%{value: %FloatWrapper{} = fw, suite_flavor: _}, _) do
    FloatWrapper.as_elixir_code(fw)
  end

  # Render JSV.Schema structs or maps with atom keys
  def render(%{value: map, suite_flavor: :jsv_schema_structs}, inspect_opts)
      when is_map(map) and not is_struct(map) do
    # Map keys in schemas are always binaries

    # Turn the map into a list ordered by key_order
    list = to_ordlist(map)

    # Force cast all keys as atoms
    list = Enum.map(list, fn {k, v} -> {String.to_atom(k), v} end)

    # Inner map is a keyword
    fun = &Inspect.List.keyword/2

    schema_struct_compatible? = Enum.all?(list, fn {k, _} -> k in @schema_struct_keys end)

    struct_name =
      if schema_struct_compatible? do
        "JSV.Schema"
      else
        ""
      end

    map_container_doc(list, struct_name, inspect_opts, fun)
  end

  # # Render maps with binary keys
  def render(%{value: map, suite_flavor: _other_flavors}, inspect_opts)
      when is_map(map) and not is_struct(map) do
    # Map keys in schemas are always binaries

    # Turn the map into a list ordered by key_order
    list = to_ordlist(map)

    # Inner map render
    fun = &to_assoc(&1, &2, " => ")

    struct_name = ""

    map_container_doc(list, struct_name, inspect_opts, fun)
  end

  defp to_assoc({key, value}, opts, sep) do
    concat(concat(to_doc(key, opts), sep), to_doc(value, opts))
  end

  defp map_container_doc(list, name, opts, fun) do
    open = "%" <> name <> "{"
    sep = ","
    close = "}"
    container_doc(open, list, close, opts, fun, separator: sep, break: :strict)
  end

  def to_ordlist(map) do
    map
    |> Map.to_list()
    |> Enum.sort_by(fn {k, _} -> order_of(k) end)
  end

  defp order_of(key) when is_binary(key) do
    case Map.fetch(@key_order, key) do
      {:ok, order} -> {0, order}
      :error -> {1, key}
    end
  end
end

defimpl Inspect, for: JSV.TestSuiteGenerator.ValueDumper do
  alias JSV.TestSuiteGenerator.ValueDumper

  def inspect(dumper, opts) do
    ValueDumper.render(dumper, opts)
  rescue
    e ->
      # Error formating will recursively try to use inspect. If the error is
      # because of ValueDumper.render own rendering code this will loop trough
      # here forever
      task =
        Task.async(fn ->
          Exception.format(:error, e, __STACKTRACE__)
        end)

      message =
        case Task.yield(task, 1000) || Task.shutdown(task) do
          {:ok, result} ->
            result

          nil ->
            "could not inspect value: #{inspect(dumper.value)} " <>
              "with `JSV.TestSuiteGenerator.ValueDumper.render/2` " <>
              "on suite flavor #{inspect(dumper.suite_flavor)}"
        end

      Mix.Shell.IO.error(message)

      System.halt(1)
  end
end
