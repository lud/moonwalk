defmodule Moonwalk.Spec.MacrogenTest do
  use ExUnit.Case, async: true

  test "no module defines take_keyword/3" do
    {:ok, mods} = :application.get_key(:moonwalk, :modules)

    Enum.each(mods, fn mod ->
      Code.ensure_loaded!(mod)
      refute {:take_keyword, 3} in mod.module_info(:exports), "module #{inspect(mod)} exports take_keyword/3"
    end)
  end
end
