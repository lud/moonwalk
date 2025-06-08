defmodule Moonwalk.Internal.ValidationBuilderTest do
  alias Moonwalk.Internal.ValidationBuilder
  alias Moonwalk.Spec.Parameter
  alias Moonwalk.Spec.MediaType
  alias Moonwalk.Spec.RequestBody
  alias Moonwalk.Spec.Operation
  alias Moonwalk.Spec.OpenAPI
  alias Moonwalk.Internal.Normalizer
  use ExUnit.Case, async: true

  defmodule BodySchema do
    require(JSV).defschema(%{
      type: :object,
      properties: %{
        some_required: %{type: :integer},
        some_optional: %{type: :string}
      },
      required: [:some_required]
    })
  end

  @normal_spec Normalizer.normalize!(%OpenAPI{
                 openapi: 123,
                 info: %{},
                 paths: %{
                   "/json-endpoint": %{
                     get: %Operation{
                       operationId: "json_1",
                       parameters: [
                         %Parameter{name: :param_p1, in: :path, schema: %{type: :integer}},
                         %Parameter{
                           name: :param_q1_orderby,
                           in: :query,
                           schema: %{type: :array, items: %{type: :string}}
                         }
                       ],
                       requestBody: %RequestBody{
                         content: %{
                           "application/json" => %MediaType{
                             schema: BodySchema
                           }
                         }
                       },
                       responses: %{}
                     }
                   }
                 }
               })

  test "build validations for request bodies" do
    assert {%{
              "json_1" => [
                parameters: %{
                  path: [
                    %{
                      in: :path,
                      key: :param_p1,
                      required: false,
                      schema_key:
                        {:precast, precast_fun,
                         {:pointer, :root,
                          ["paths", "/json-endpoint", "get", "parameters", 0, "schema"]}},
                      bin_key: "param_p1"
                    }
                  ],
                  query: [
                    %{
                      in: :query,
                      key: :param_q1_orderby,
                      required: false,
                      schema_key:
                        {:pointer, :root,
                         ["paths", "/json-endpoint", "get", "parameters", 1, "schema"]},
                      bin_key: "param_q1_orderby"
                    }
                  ]
                },
                require_body: false,
                body: [
                  {{"application", "json"},
                   {:pointer, :root,
                    [
                      "paths",
                      "/json-endpoint",
                      "get",
                      "requestBody",
                      "content",
                      "application/json",
                      "schema"
                    ]}}
                ]
              ]
            }, _} = ValidationBuilder.build_operations(@normal_spec)

    %{module: JSV.Cast, name: :string_to_integer, arity: 1} = Map.new(Function.info(precast_fun))
  end
end
