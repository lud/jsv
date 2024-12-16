defmodule JSV.MacrogenTest do
  use ExUnit.Case, async: true

  test "no module should define take_keyword/3 anymore" do
    {:ok, mods} = :application.get_key(:jsv, :modules)

    Enum.each(mods, fn mod ->
      Code.ensure_loaded!(mod)
      refute {:take_keyword, 3} in mod.module_info(:exports), "module #{inspect(mod)} exports take_keyword/3"
    end)
  end
end