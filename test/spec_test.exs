defmodule Moonwalk.SpecTest do
  use ExUnit.Case, async: true

  alias Moonwalk.Spec.Api

  test "define an empty API" do
    api = Api.define([])
    assert %{"openapi" => "4.0.0"} == Moonwalk.normalize_spec(api)
  end

  test "an API can bear info" do
    title = "Some title"
    api = Api.define(title: title)
    assert %{"openapi" => "4.0.0", "info" => %{"title" => title}} == Moonwalk.normalize_spec(api)
  end
end
