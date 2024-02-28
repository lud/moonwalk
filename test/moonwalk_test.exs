defmodule MoonwalkTest do
  use ExUnit.Case
  doctest Moonwalk

  test "greets the world" do
    assert Moonwalk.hello() == :world
  end
end
