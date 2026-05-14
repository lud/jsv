# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule JSV.Resolver.LocalTest do
  alias JSV.Codec

  import ExUnit.CaptureIO
  use ExUnit.Case, async: true

  doctest JSV.Resolver.Local

  defp generate_dir(filemap) do
    dir = Briefly.create!(directory: true, prefix: "jsv")

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
    path = Briefly.create!(extname: ".json", prefix: "jsv")
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
    test "behaviour attribute is declared" do
      defmodule BehaviourSource do
        use JSV.Resolver.Local, source: []
      end

      assert [JSV.Resolver] == Keyword.fetch!(BehaviourSource.module_info(:attributes), :behaviour)
    end

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

      assert {:normal, schema_1} == DirSource.resolve("test://schema-1/", [])
      assert {:normal, schema_2} == DirSource.resolve("test://schema-2/", [])
      assert {:error, _} = DirSource.resolve("test://schema-3/", [])
    end

    test "with a directory source and a trailing slash" do
      schema_1 = %{"$id" => "test://schema-1/", "type" => "object"}
      schema_2 = %{"$id" => "test://schema-2/", "type" => "string"}

      dir =
        generate_dir(%{
          "schema-1.json" => Codec.format!(schema_1),
          "schema-2.json" => Codec.format!(schema_2)
        })

      source = dir <> "/"

      defmodule TrailingSlashSource do
        use JSV.Resolver.Local, source: source
      end

      assert {:normal, schema_1} == TrailingSlashSource.resolve("test://schema-1/", [])
      assert {:normal, schema_2} == TrailingSlashSource.resolve("test://schema-2/", [])
      assert {:error, _} = TrailingSlashSource.resolve("test://schema-3/", [])
    end

    test "with a list nested source" do
      schema_1 = %{"$id" => "test://schema-1/", "type" => "object"}
      schema_2 = %{"$id" => "test://schema-2/", "type" => "string"}
      schema_3 = %{"$id" => "test://schema-3/", "type" => "string"}

      dir =
        generate_dir(%{
          "schema-1.json" => Codec.format!(schema_1),
          "schema-2.json" => Codec.format!(schema_2)
        })

      file = generate_file(Codec.format!(schema_3))

      source = dir <> "/"

      defmodule NestedListSource do
        use JSV.Resolver.Local, source: [[[[[dir], [[[[[file]]]]]]]]]
      end

      assert {:normal, schema_1} == NestedListSource.resolve("test://schema-1/", [])
      assert {:normal, schema_2} == NestedListSource.resolve("test://schema-2/", [])
      assert {:normal, schema_3} == NestedListSource.resolve("test://schema-3/", [])
    end

    test "using attribute or variables in macros" do
      schema_1 = %{"$id" => "test://schema-1/", "type" => "object"}
      schema_2 = %{"$id" => "test://schema-2/", "type" => "string"}

      dir_1 =
        generate_dir(%{
          "schema-1.json" => Codec.format!(schema_1)
        })

      dir_2 =
        generate_dir(%{
          "schema-2.json" => Codec.format!(schema_2)
        })

      defmodule AttrSource do
        @attr_source dir_1
        var_source = dir_2
        use JSV.Resolver.Local, source: [@attr_source, var_source]
      end

      assert {:normal, schema_1} == AttrSource.resolve("test://schema-1/", [])
      assert {:normal, schema_2} == AttrSource.resolve("test://schema-2/", [])
      assert {:error, _} = AttrSource.resolve("test://schema-3/", [])
    end

    test "the resolve/1 function is also defined" do
      schema = %{"$id" => "test://helper-test/", "type" => "string"}

      dir = generate_dir(%{"schema.json" => Codec.format!(schema)})

      defmodule HelperSource do
        use JSV.Resolver.Local, source: dir
      end

      # Default function/2
      assert {:normal, schema} == HelperSource.resolve("test://helper-test/", [])

      # Helper function/1
      assert {:ok, schema} == HelperSource.resolve("test://helper-test/")
    end

    test "the resolve/2 function is overrideable" do
      defmodule OverrideSource do
        use JSV.Resolver.Local, source: []

        def resolve(_, _) do
          {:error, :overriden_in_usermod}
        end
      end

      assert {:error, :overriden_in_usermod} == OverrideSource.resolve("test://helper-test/", [])
    end

    test "the __mix_recompile__? function is overrideable" do
      defmodule BadRecompileSource do
        use JSV.Resolver.Local, source: []

        def __mix_recompile__? do
          :maybe
        end
      end

      assert :maybe == BadRecompileSource.__mix_recompile__?()
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
            use JSV.Resolver.Local,
              source: [dir, "/tmp/some/non/existing", :not_a_binary, "gibberish ! $ * #"],
              warn: true
          end
        end)

      out = strip_ansi(out)

      assert out =~ "could not read file: /tmp/some/non/existing"
      assert out =~ "could not read file: gibberish"
      assert out =~ "array.json is not an object"
      assert out =~ "boolean.json is not an object"
      assert out =~ "no_id.json does not have $id"
      assert out =~ ~r/could not decode json schema.*invalid\.json/
      assert out =~ ~r/could not decode json schema.*empty\.json/
      assert out =~ ~r/invalid source,.*got: :not_a_binary/

      alias __MODULE__.WithWarnings

      assert {:normal, valid_schema} == WithWarnings.resolve("test://valid-schema/", [])
    end

    # Windows does not honour POSIX-style chmod(0) to deny read access, so the
    # file remains readable and there is no error to surface.
    @tag skip: match?({:win32, _}, :os.type())
    test "file access error" do
      file = generate_file(Codec.format!(%{"$id" => "test://schema-1/", "type" => "object"}))
      File.chmod!(file, 0o000)

      defmodule FileErrorSource do
        @source file
        use JSV.Resolver.Local, source: @source, warn: false
      end

      assert {:error, _} = FileErrorSource.resolve("test://schema-1/", [])
    end

    test "duplicate ids are not supported" do
      schema_1 = %{"$id" => "test://schema-1/", "type" => "object"}
      schema_2 = %{"$id" => "test://schema-1/", "type" => "string"}

      dir =
        generate_dir(%{
          "schema-1.json" => Codec.format!(schema_1),
          "schema-2.json" => Codec.format!(schema_2)
        })

      define = fn ->
        defmodule DupIdsSource do
          use JSV.Resolver.Local, source: dir
        end
      end

      # define.()
      err = catch_error(define.())

      assert %RuntimeError{} = err

      assert err.message =~ ~S(duplicate $id "test://schema-1/")
    end

    test "duplicate ids are supported if from the same file" do
      schema = %{"$id" => "test://schema-1/", "type" => "object"}

      # Force the paths to be relative and not absolute path as Briefly would
      # return so we can test that the resolver will expand the paths to find
      # possible duplicates. Not testing symlinks though.

      file =
        Codec.format!(schema)
        |> generate_file()
        |> Path.relative_to(File.cwd!(), force: true)

      # Construct a second string referring to the same file by detouring
      # through `../<cwd-basename>` — that normalizes back to the original
      # regardless of how deep the temp file lives relative to cwd (Briefly's
      # temp dir is ~4 levels up on Windows, 2 levels up on most Linux setups).
      file_with_different_path = Path.join(["..", Path.basename(File.cwd!()), file])

      defmodule DupIdsSameFileSource do
        use JSV.Resolver.Local, source: [file, file, file_with_different_path]
      end

      assert ["test://schema-1/"] == DupIdsSameFileSource.resolvable_ids()
      assert {:normal, schema} == DupIdsSameFileSource.resolve("test://schema-1/", [])
    end

    test "$id is not an URI" do
      schema = %{"$id" => "hello world", "type" => "integer"}

      file = generate_file(Codec.format!(schema))

      defmodule BadIdSource do
        use JSV.Resolver.Local, source: file
      end

      # The $id is not checked at the resolver level

      assert {:normal, schema} == BadIdSource.resolve("hello world", [])

      # But we cannot build anything with that

      assert {
               :error,
               %JSV.BuildError{
                 reason: {:invalid_ns_merge, :root, "hello world"},
                 __exception__: true
               }
             } = JSV.build(%{"$ref" => "hello world"}, resolver: BadIdSource)

      # same with a parent URI without a scheme

      assert {
               :error,
               %JSV.BuildError{
                 reason: {:invalid_ns_merge, "some:uri", "hello world"},
                 __exception__: true
               }
             } = JSV.build(%{"$id" => "some:uri", "$ref" => "hello world"}, resolver: BadIdSource)

      # With a mergeable root namespace, the $id to resolve will become an URI
      # and not just "hello world", so it does not work either.

      assert {
               :error,
               %JSV.BuildError{
                 reason: {
                   :resolver_error,
                   [
                     "Elixir.JSV.Resolver.LocalTest.BadIdSource": {:unknown_id, "myapp://base/hello world"},
                     "Elixir.JSV.Resolver.Embedded": {:not_embedded, "myapp://base/hello world"},
                     "Elixir.JSV.Resolver.Internal": {:unsupported, "myapp://base/hello world"}
                   ]
                 }
               }
             } = JSV.build(%{"$id" => "myapp://base", "$ref" => "hello world"}, resolver: BadIdSource)
    end
  end

  defp strip_ansi(ansi_string) when is_binary(ansi_string) do
    Regex.replace(~r/(\x9B|\x1B\[)[0-?]*[ -\/]*[@-~]/, ansi_string, "")
  end

  describe "recompilation" do
    test "recompiles on file change" do
      file = generate_file(Codec.format!(%{"$id" => "test://schema-1/", "type" => "object"}))

      defmodule FileChanged do
        use JSV.Resolver.Local, source: file
      end

      assert {:normal, _} = FileChanged.resolve("test://schema-1/", [])

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

      assert {:normal, _} = FileDeleted.resolve("test://schema-1/", [])

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

      assert {:normal, schema_1} == FileAdded.resolve("test://schema-1/", [])
      refute FileAdded.__mix_recompile__?()

      # Add a new schema file to the directory
      schema_2 = %{"$id" => "test://schema-2/", "type" => "string"}
      File.write!(Path.join(dir, "schema-2.json"), Codec.format!(schema_2))

      assert FileAdded.__mix_recompile__?()
    end
  end
end
