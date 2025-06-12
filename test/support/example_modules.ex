# credo:disable-for-this-file Credo.Check.Readability.Specs
# credo:disable-for-this-file Credo.Check.Readability.ModuleDoc

defmodule MyApp.UserSchema do
  require JSV

  JSV.defschema(%{
    type: :object,
    properties: %{
      name: %{type: :string, default: ""},
      age: %{type: :integer, default: 123}
    }
  })
end

defmodule MyApp.CompanySchema do
  require JSV

  JSV.defschema(%{
    type: :object,
    properties: %{
      name: %{type: :string},
      owner: MyApp.UserSchema
    }
  })
end

defmodule MyApp.LocalResolver do
  require JSV
  use JSV.Resolver.Local, source: __ENV__.file |> Path.dirname() |> Path.join("schemas")
end

defmodule MyApp.Organization do
  defstruct [:name, :id]
end

defmodule MyApp.OrganizationSchema do
  require JSV

  JSV.defschema_for(MyApp.Organization, %{
    type: :object,
    properties: %{
      id: %{type: :string, format: :uuid},
      name: %{type: :string}
    }
  })
end

defmodule CustomSchemaStruct do
  defstruct [:type, :description]
end

defmodule Elixir.ASchemaExportingModule do
  def schema do
    %{}
  end
end

defmodule AModuleWithoutExportedSchema do
  def hello do
    "world"
  end
end

defmodule MyApp.Cast do
  import JSV

  defcast :to_integer
  defcast "to_integer_if_string", :to_integer

  defp to_integer(data) when is_binary(data) do
    case Integer.parse(data) do
      {int, ""} -> {:ok, int}
      _ -> {:error, "invalid"}
    end
  end

  defp to_integer(_) do
    {:error, "invalid"}
  end

  defcast to_existing_atom(data) do
    {:ok, String.to_existing_atom(data)}
  rescue
    ArgumentError -> {:error, "bad atom"}
  end
end
