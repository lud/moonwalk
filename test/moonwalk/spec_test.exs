defmodule Moonwalk.SpecTest do
  alias Moonwalk.Spec
  alias Moonwalk.Spec.Components
  alias Moonwalk.Spec.MediaType
  alias Moonwalk.Spec.OpenAPI
  alias Moonwalk.Spec.Operation
  alias Moonwalk.Spec.PathItem
  alias Moonwalk.Spec.Paths
  alias Moonwalk.Spec.RequestBody
  alias Moonwalk.Spec.SchemaWrapper
  alias Moonwalk.TestWeb
  use ExUnit.Case, async: true

  test "meta - handling references and schema wrappers in oneOf/anyOf" do
    # * all spec schemas using a Reference should put the reference first because
    # references share common keys and only require $ref
    # * all schema wrappers should be last as they accept any data
    JSV.Helpers.Traverse.prewalk(OpenAPI.schema(), %{}, fn
      {:val, %{oneOf: one_of} = map}, acc ->
        if Moonwalk.Spec.Reference in one_of do
          flunk("reference should be given in anyOf, got oneOf: #{inspect(one_of)}")
        end

        if Moonwalk.Spec.SchemaWrapper in one_of and SchemaWrapper != List.last(one_of) do
          flunk("schema wrapper not used last in oneOf: #{inspect(one_of)}")
        end

        {map, acc}

      {:val, %{anyOf: any_of} = map}, acc ->
        if Moonwalk.Spec.Reference in any_of and Moonwalk.Spec.Reference != hd(any_of) do
          flunk("reference not used first in anyOf: #{inspect(any_of)}")
        end

        if Moonwalk.Spec.SchemaWrapper in any_of and SchemaWrapper != List.last(any_of) do
          flunk("schema wrapper not used last in anyOf: #{inspect(any_of)}")
        end

        {map, acc}

      {:val, module}, acc when is_map_key(acc, module) ->
        {:already_seen, acc}

      {:val, module}, acc when is_atom(module) ->
        if JSV.Schema.schema_module?(module) do
          # wrap in a list to re enter the traversal in case the schema has
          # oneOf at the root
          {[module.schema()], Map.put(acc, module, true)}
        else
          {module, acc}
        end

      t, acc ->
        {elem(t, 1), acc}
    end)
  end

  test "minimal test" do
    assert %OpenAPI{} =
             %{
               "openapi" => "hello",
               :info => %{"title" => "Some title", :version => "3.1"},
               :paths => %{}
             }
             |> Spec.normalize!()
             |> cast_to_structs()
  end

  test "petstore with references" do
    # the used document does not contain schemas as modules (it's a raw json)
    json =
      "test/support/data/petstore-refs.json"
      |> File.read!()
      |> JSV.Codec.decode!()

    assert %OpenAPI{} =
             Spec.normalize!(json)
             |> cast_to_structs()
  end

  defmodule Standalone do
    import JSV
    alias Moonwalk.SpecTest.MutualRecursiveB

    def schema do
      %{
        title: "Standalone",
        type: :integer
      }
    end
  end

  defmodule MutualRecursiveA do
    import JSV
    alias Moonwalk.SpecTest.MutualRecursiveB

    defschema(%{
      type: :object,
      title: "RecA",
      properties: %{
        b: MutualRecursiveB
      }
    })
  end

  defmodule MutualRecursiveB do
    import JSV

    defschema(%{
      type: :object,
      properties: %{
        a: MutualRecursiveA
      }
    })
  end

  IO.warn("todo register bare map schema")
  IO.warn("todo register bare map schema with nested module")
  IO.warn("todo register boolean schema")

  test "registering schemas in components" do
    assert %Moonwalk.Spec.OpenAPI{
             openapi: "3.1.0",
             info: %Moonwalk.Spec.Info{
               title: "some title",
               version: "0.0.0"
             },
             components: %Components{
               schemas: %{
                 # schema A defines a custom title, schema B does not and is
                 # registered with its module name
                 "Standalone" => %{"type" => "integer"},
                 "RecA" => %{
                   "properties" => %{
                     "b" => %{"$ref" => "#/components/schemas/Moonwalk.SpecTest.MutualRecursiveB"}
                   }
                 },
                 "Moonwalk.SpecTest.MutualRecursiveB" => %{
                   "properties" => %{"a" => %{"$ref" => "#/components/schemas/RecA"}}
                 }
               }
             },
             paths: %{
               "some_path" => %Moonwalk.Spec.PathItem{
                 get: %Moonwalk.Spec.Operation{
                   operationId: "test_get",
                   parameters: [
                     %Moonwalk.Spec.Parameter{
                       name: "some_param",
                       schema: %{"$ref" => "#/components/schemas/Standalone"}
                     }
                   ],
                   responses: %{
                     "200" => %Moonwalk.Spec.Response{
                       description: "some description",
                       content: %{
                         "application/json" => %Moonwalk.Spec.MediaType{
                           schema: %{"$ref" => "#/components/schemas/Standalone"}
                         }
                       }
                     }
                   }
                 },
                 post: %Moonwalk.Spec.Operation{
                   operationId: "test_post",
                   responses: %{
                     "200" => %Moonwalk.Spec.Response{
                       description: "some description"
                     }
                   },
                   requestBody: %Moonwalk.Spec.RequestBody{
                     content: %{
                       "application/json" => %Moonwalk.Spec.MediaType{
                         schema: %{"$ref" => "#/components/schemas/RecA"}
                       }
                     }
                   }
                 }
               }
             }
           } =
             Spec.normalize!(%{
               openapi: "3.1.0",
               info: %{title: "some title", version: "0.0.0"},
               paths: %{
                 some_path: %PathItem{
                   get: %Operation{
                     operationId: "test_get",
                     parameters: [%{in: :query, name: :some_param, schema: Standalone}],
                     responses: %{
                       200 => %{
                         description: "some description",
                         content: %{"application/json" => %{schema: Standalone}}
                       }
                     }
                   },
                   post: %Operation{
                     operationId: "test_post",
                     responses: %{200 => %{description: "some description"}},
                     requestBody: %RequestBody{
                       content: %{"application/json": %MediaType{schema: MutualRecursiveA}}
                     }
                   }
                 }
               }
             })
             |> cast_to_structs()
  end

  describe "phoenix routes" do
    test "extracting operations from phoenix routes" do
      assert %Moonwalk.Spec.OpenAPI{
               paths: %{
                 "/body/form" => %Moonwalk.Spec.PathItem{},
                 "/body/inline-single" => %Moonwalk.Spec.PathItem{},
                 "/body/module-single" => %Moonwalk.Spec.PathItem{},
                 "/body/wildcard" => %Moonwalk.Spec.PathItem{},
                 "/params/arrays" => %Moonwalk.Spec.PathItem{},
                 "/params/generic" => %Moonwalk.Spec.PathItem{},
                 "/params/s/{shape}" => %Moonwalk.Spec.PathItem{},
                 "/params/s/{shape}/t/{theme}" => %Moonwalk.Spec.PathItem{},
                 "/params/s/{shape}/t/{theme}/c/{color}" => %Moonwalk.Spec.PathItem{},
                 "/params/t/{theme}" => %Moonwalk.Spec.PathItem{},
                 "/params/t/{theme}/c/{color}" => %Moonwalk.Spec.PathItem{}
               }
             } =
               %{
                 :openapi => "3.1.1",
                 :info => %{"title" => "Moonwalk Test API", :version => "0.0.0"},
                 :paths => Paths.from_router(TestWeb.Router)
               }
               |> Spec.normalize!()
               |> cast_to_structs()
    end
  end

  IO.warn("""
  todo test multiple schemas with same title.

  We do not want to sort all keys at all levels in the spec for it to be
  deterministic. Maybe we can just sort when normalize_subs is called with a
  function that will iterate on all keys, it's the only point when keys are not
  given in order
  """)

  IO.warn("""
  todo test that we can just pass an %Operation{} struct to the operation macro
  """)

  defp cast_to_structs(normal) do
    Moonwalk.Spec.Validator.validate!(normal)
  end
end
