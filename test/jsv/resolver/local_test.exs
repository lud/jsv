defmodule JSV.Resolver.LocalTest do
  alias JSV.Codec
  alias JSV.Resolver.Local
  use ExUnit.Case, async: true

  defp generate_dir(filemap) do
    dir = Briefly.create!(directory: true)

    filemap
    |> flatten_filemap(dir, [])
    |> Enum.each(fn {path, contents} ->
      path
      |> Path.dirname()
      |> File.mkdir_p!()

      File.write!(path, contents)
    end)

    dir
  end

  defp flatten_filemap(filemap, dir, acc) when is_map(filemap) do
    Enum.reduce(filemap, acc, fn
      {path, contents}, acc when is_binary(contents) -> [{Path.join(dir, path), contents} | acc]
      {path, subs}, acc when is_map(subs) -> flatten_filemap(subs, Path.join(dir, path), acc)
    end)
  end

  describe "meta" do
    test "meta - can generate test files" do
      filemap = %{
        "rootfile" => "content in rootfile",
        "subdir/subfile" => "content in subdir/subfile",
        "subdir/subsubdir/subsubfile" => "content in subdir/subsubdir/subsubfile",
        # supports nested maps
        "a" => %{"b" => %{"c" => "content in a/b/c"}}
      }

      dir = generate_dir(filemap)

      assert "content in rootfile" == File.read!(Path.join(dir, "rootfile"))
      assert "content in subdir/subfile" == File.read!(Path.join(dir, "subdir/subfile"))
      assert "content in subdir/subsubdir/subsubfile" == File.read!(Path.join(dir, "subdir/subsubdir/subsubfile"))
      assert "content in a/b/c" == File.read!(Path.join(dir, "a/b/c"))
    end
  end

  describe "resolve from compilation" do
    test "with a directory source" do
      schema_1 = %{"$id" => "test://schema-1/", "type" => "object"}
      schema_2 = %{"$id" => "test://schema-2/", "type" => "string"}

      dir =
        generate_dir(%{
          "schema-1.json" => Codec.format!(schema_1),
          "schema-2.json" => Codec.format!(schema_2)
        })

      defmodule DirSource do
        use JSV.Resolver.Local, source: dir
      end

      assert {:ok, schema_1} == DirSource.resolve("test://schema-1/", [])
      assert {:ok, schema_2} == DirSource.resolve("test://schema-2/", [])
      assert {:error, _} = DirSource.resolve("test://schema-3/", [])
    end

    test "with an attribute source" do
      schema_1 = %{"$id" => "test://schema-1/", "type" => "object"}
      schema_2 = %{"$id" => "test://schema-2/", "type" => "string"}

      dir =
        generate_dir(%{
          "schema-1.json" => Codec.format!(schema_1),
          "schema-2.json" => Codec.format!(schema_2)
        })

      defmodule AttrSource do
        @source dir
        use JSV.Resolver.Local, source: @source
      end

      assert {:ok, schema_1} == AttrSource.resolve("test://schema-1/", [])
      assert {:ok, schema_2} == AttrSource.resolve("test://schema-2/", [])
      assert {:error, _} = AttrSource.resolve("test://schema-3/", [])
    end
  end

  IO.warn("todo test unexisting sources")
  IO.warn("todo test source as list of json files")
  IO.warn("todo test source as single json file")
  IO.warn("todo test source as mixed files and dirs")
  IO.warn("todo test source with invalid JSON")
  IO.warn("todo test source with missing $id")
  IO.warn("todo test recompilation")
end
