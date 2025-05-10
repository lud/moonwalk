defmodule Moonwalk.ControllerTest do
  alias Moonwalk.Spec.MediaType
  alias Moonwalk.Spec.Operation
  alias Moonwalk.Spec.RequestBody
  use ExUnit.Case, async: true

  describe "operation definition" do
    test "define with inline request body schema" do
      spec = [
        operation_id: :some_operation,
        # passing a map as the request body is handled as a schema. we should
        # have a default content type of application/json associated with this
        # schema.
        request_body: %{type: :string},
        tags: [:a, :b],
        description: "some description",
        summary: "some summary"
      ]

      op = Operation.from_controller!(spec)

      assert %Operation{
               description: "some description",
               summary: "some summary",
               operationId: :some_operation,
               tags: [:a, :b],
               requestBody: %RequestBody{
                 content: %{
                   "application/json" => %MediaType{
                     schema: %{type: :string}
                   }
                 }
               }
             } = op
    end
  end
end
