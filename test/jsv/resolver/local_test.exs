defmodule JSV.Resolver.LocalTest do
  alias JSV.Codec
  import ExUnit.CaptureIO
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

  defp generate_file(content) do
    # path = Briefly.create!(extname: ".json")
    path = "/tmp/some-file.json"
    File.write!(path, content)
    path
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

  describe "error handling" do
    test "various error cases" do
      valid_schema = %{"$id" => "test://valid-schema/", "type" => "object"}

      filemap = %{
        "valid.json" => Codec.format!(valid_schema),
        "invalid.json" => "invalid json content",
        "array.json" => Codec.format!(["array", "of", "strings"]),
        "boolean.json" => Codec.format!(true),
        "no_id.json" => Codec.format!(%{"type" => "object"}),
        "empty.json" => ""
      }

      dir = generate_dir(filemap)

      out =
        capture_io(:stderr, fn ->
          defmodule WithWarnings do
            use JSV.Resolver.Local, source: [dir, "/tmp/some/non/existing"], warn: true
          end
        end)

      out = strip_ansi(out)

      assert out =~ "source not found: /tmp/some/non/existing"
      assert out =~ "array.json is not an object"
      assert out =~ "boolean.json is not an object"
      assert out =~ "no_id.json does not have $id"
      assert out =~ ~r/could not decode json schema.*invalid\.json/
      assert out =~ ~r/could not decode json schema.*empty\.json/

      alias __MODULE__.WithWarnings

      assert {:ok, valid_schema} == WithWarnings.resolve("test://valid-schema/", [])
    end
  end

  @ansi_regex ~r/(\x9B|\x1B\[)[0-?]*[ -\/]*[@-~]/

  defp strip_ansi(ansi_string) when is_binary(ansi_string) do
    Regex.replace(@ansi_regex, ansi_string, "")
  end

  describe "recompilation" do
    test "recompiles on file change" do
      file = generate_file(Codec.format!(%{"$id" => "test://schema-1/", "type" => "object"}))

      defmodule FileChanged do
        use JSV.Resolver.Local, source: file
      end

      assert {:ok, _} = FileChanged.resolve("test://schema-1/", [])

      # When the file has not changed, no recompilation should happen
      refute FileChanged.__mix_recompile__?()

      # If the source file changes, recompilation should happen
      #
      # Change check is based on date and size. Test is executed instantly so we will make the size vary
      File.write!(file, Codec.format!(%{"$id" => "test://schema-1/", "type" => "string", "enum" => ["stuff"]}))
      assert FileChanged.__mix_recompile__?()
    end

    test "recompiles on file deletion" do
      file = generate_file(Codec.format!(%{"$id" => "test://schema-1/", "type" => "object"}))

      defmodule FileDeleted do
        use JSV.Resolver.Local, source: file
      end

      assert {:ok, _} = FileDeleted.resolve("test://schema-1/", [])

      # When the file has not changed, no recompilation should happen
      refute FileDeleted.__mix_recompile__?()

      # If the source file is deleted, recompilation should happen
      File.rm!(file)
      assert FileDeleted.__mix_recompile__?()
    end

    test "recompiles on file addition" do
      schema_1 = %{"$id" => "test://schema-1/", "type" => "object"}
      dir = generate_dir(%{"schema-1.json" => Codec.format!(schema_1)})

      defmodule FileAdded do
        use JSV.Resolver.Local, source: dir
      end

      assert {:ok, schema_1} == FileAdded.resolve("test://schema-1/", [])
      refute FileAdded.__mix_recompile__?()

      # Add a new schema file to the directory
      schema_2 = %{"$id" => "test://schema-2/", "type" => "string"}
      File.write!(Path.join(dir, "schema-2.json"), Codec.format!(schema_2))

      assert FileAdded.__mix_recompile__?()
    end
  end

  IO.warn("todo test resolves using internal")
  IO.warn("todo duplicate ids")
end
