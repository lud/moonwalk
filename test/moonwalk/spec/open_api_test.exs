defmodule Moonwalk.Spec.OpenAPITest do
  alias Moonwalk.Spec.OpenAPI
  use ExUnit.Case, async: true

  test "can generate an opeanapi specification" do
    OpenAPI.build!(openapi: "3.1.1", info: %{})
  end
end
