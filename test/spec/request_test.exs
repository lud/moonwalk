defmodule Moonwalk.Spec.RequestTest do
  alias Moonwalk.Spec.Request
  use ExUnit.Case, async: true

  test "minimal request" do
    req = Request.define([])
    assert "GET" == req.method
    assert %{"method" => "GET"} == Moonwalk.normalize_spec(req)
  end

  test "with content type" do
    req = Request.define(content_type: "application/json", method: "POST")
    assert "POST" == req.method
    assert "application/json" == req.content_type

    assert %{"method" => "POST", "contentType" => "application/json"} ==
             Moonwalk.normalize_spec(req)
  end
end
