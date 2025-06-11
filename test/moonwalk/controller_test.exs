defmodule Moonwalk.ControllerTest do
  alias Moonwalk.Spec.MediaType
  alias Moonwalk.Spec.Operation
  alias Moonwalk.Spec.RequestBody
  use ExUnit.Case, async: true

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

  describe "required body" do
    test "when using shortcut, body is required by default" do
      defmodule SomeInlineSchema do
        alias Moonwalk.ControllerTest.SomeInlineSchema
        require(JSV).defschema(JSV.Schema.props(a: %{type: :integer}))
      end

      # spec with a direct schema is required
      spec0 = [operation_id: :some_operation, request_body: SomeInlineSchema]
      op0 = Operation.from_controller!(spec0)
      assert %Operation{requestBody: %RequestBody{required: true}} = op0

      # spec with a schema and options is required
      spec1 = [operation_id: :some_operation, request_body: {SomeInlineSchema, []}]
      op1 = Operation.from_controller!(spec1)
      assert %Operation{requestBody: %RequestBody{required: true}} = op1

      # spec with a schema and options can be made non-required
      spec2 = [operation_id: :some_operation, request_body: {SomeInlineSchema, [required: false]}]
      op2 = Operation.from_controller!(spec2)
      assert %Operation{requestBody: %RequestBody{required: false}} = op2

      # spec with a nested definition will respect the definition
      spec3 = [
        operation_id: :some_operation,
        request_body: [content: %{"application/json" => [schema: SomeInlineSchema]}]
      ]

      op3 = Operation.from_controller!(spec3)
      assert %Operation{requestBody: %RequestBody{required: false}} = op3
    end
  end
end
