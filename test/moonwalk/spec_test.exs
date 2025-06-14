defmodule Moonwalk.SpecTest do
  alias Moonwalk.Spec.Components
  alias Moonwalk.Spec.OpenAPI
  alias Moonwalk.Spec.Paths
  alias Moonwalk.TestWeb
  alias Moonwalk.TestWeb.DeclarativeApiSpec
  use ExUnit.Case, async: true

  test "minimal test" do
    assert %OpenAPI{} =
             %{
               "openapi" => "hello",
               :info => %{"title" => "Some title", :version => "3.1"},
               :paths => %{}
             }
             |> Moonwalk.normalize_spec!()
             |> cast_to_structs()
  end

  test "petstore with references" do
    # the used document does not contain schemas as modules (it's a raw json)
    json =
      "test/support/data/petstore-refs.json"
      |> File.read!()
      |> JSV.Codec.decode!()

    assert %OpenAPI{} =
             Moonwalk.normalize_spec!(json)
             |> cast_to_structs()
  end

  test "raw spec from module" do
    # The DeclarativeApiSpec spec contains all special cases that we want to
    # test when normalizing/building from a raw document, notably using
    # references for various components.
    assert %Moonwalk.Spec.OpenAPI{
             openapi: "3.1.0",
             info: %Moonwalk.Spec.Info{
               title: "Alchemy Lab API",
               version: "1.0.0"
             },
             components: %Moonwalk.Spec.Components{
               parameters: %{
                 "DryRun" => %Moonwalk.Spec.Parameter{
                   in: :query,
                   name: "dry_run",
                   schema: %{"type" => "boolean"}
                 },
                 "Source" => %Moonwalk.Spec.Parameter{
                   in: :query,
                   name: "source",
                   schema: %{"type" => "string"}
                 }
               },
               pathItems: %{
                 "CreatePotionPath" => %Moonwalk.Spec.PathItem{
                   post: %Moonwalk.Spec.Operation{
                     operationId: "createPotion",
                     parameters: [
                       %Moonwalk.Spec.Reference{
                         "$ref": "#/components/parameters/DryRun"
                       },
                       %Moonwalk.Spec.Reference{
                         "$ref": "#/components/parameters/Source"
                       }
                     ],
                     requestBody: %Moonwalk.Spec.Reference{
                       "$ref": "#/components/requestBodies/CreatePotionRequest"
                     },
                     responses: %{
                       "200" => %Moonwalk.Spec.Reference{
                         "$ref": "#/components/responses/PotionCreated"
                       }
                     }
                   }
                 }
               },
               requestBodies: %{
                 "CreatePotionRequest" => %Moonwalk.Spec.RequestBody{
                   content: %{
                     "application/json" => %Moonwalk.Spec.MediaType{
                       schema: %{"$ref" => "#/components/schemas/CreatePotionBody"}
                     }
                   },
                   required: true
                 }
               },
               responses: %{
                 "PotionCreated" => %Moonwalk.Spec.Response{
                   content: %{
                     "application/json" => %Moonwalk.Spec.MediaType{
                       schema: %{"$ref" => "#/components/schemas/Potion"}
                     }
                   },
                   description: "Potion created successfully"
                 }
               },
               schemas: %{
                 "CreatePotionBody" => %{
                   "jsv-cast" => ["Elixir.Moonwalk.TestWeb.DeclarativeApiSpec.CreatePotionBody", 0],
                   "properties" => %{
                     "ingredients" => %{
                       "items" => %{
                         "$ref" => "#/components/schemas/Ingredient"
                       },
                       "type" => "array"
                     },
                     "name" => %{"type" => "string"}
                   },
                   "required" => ["name", "ingredients"],
                   "type" => "object"
                 },
                 "Ingredient" => %{
                   "jsv-cast" => ["Elixir.Moonwalk.TestWeb.DeclarativeApiSpec.Ingredient", 0],
                   "properties" => %{
                     "name" => %{"type" => "string"},
                     "quantity" => %{"type" => "integer"},
                     "unit" => %{
                       "enum" => ["pinch", "dash", "scoop", "whiff", "nub"],
                       "type" => "string"
                     }
                   },
                   "required" => ["name", "quantity", "unit"],
                   "type" => "object"
                 },
                 "Potion" => %{
                   "jsv-cast" => ["Elixir.Moonwalk.TestWeb.DeclarativeApiSpec.Potion", 0],
                   "properties" => %{
                     "brewingTime" => %{"type" => "integer"},
                     "id" => %{"type" => "string"},
                     "ingredients" => %{
                       "items" => %{
                         "$ref" => "#/components/schemas/Ingredient"
                       },
                       "type" => "array"
                     },
                     "name" => %{"type" => "string"}
                   },
                   "required" => ["id", "name", "ingredients"],
                   "type" => "object"
                 }
               }
             },
             paths: %{
               "/potions" => %Moonwalk.Spec.Reference{
                 "$ref": "#/components/pathItems/CreatePotionPath"
               }
             }
           } =
             DeclarativeApiSpec.spec()
             |> Moonwalk.normalize_spec!()
             |> cast_to_structs()
  end

  describe "normalizing schemas" do
    # returns a Paths object
    #
    # If 2 schemas are given, then the 2 paths are "/p1" and "/p2", the
    # operations are "op1" and "op2" respectively.
    #
    # Schemas are used as both the request body and response body
    defp schemas_to_paths(schemas) do
      schemas
      |> Enum.with_index(1)
      |> Map.new(fn {schema, i} ->
        path = "/p#{i}"
        opid = "op#{i}"

        pathitem = %{
          "post" => %{
            "operationId" => opid,
            "responses" => %{
              "200" => %{"description" => "resp #{i}", "content" => %{"application/json" => %{"schema" => schema}}}
            },
            "requestBody" => %{
              "content" => %{"application/json" => %{"schema" => schema}}
            }
          }
        }

        {path, pathitem}
      end)
    end

    defp base(overrides) do
      Map.merge(%{"openapi" => "3.1.1", "info" => %{"title" => "spec_with_schemas", "version" => "0"}}, overrides)
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

    test "recursive schemas in components" do
      assert %Moonwalk.Spec.OpenAPI{
               openapi: "3.1.1",
               info: %Moonwalk.Spec.Info{
                 title: "spec_with_schemas",
                 version: "0"
               },
               components: %Components{
                 schemas: %{
                   # schema A defines a custom title, schema B does not and is
                   # registered with its module name
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
                 "/p1" => %Moonwalk.Spec.PathItem{
                   post: %Moonwalk.Spec.Operation{
                     operationId: "op1",
                     requestBody: %Moonwalk.Spec.RequestBody{
                       content: %{
                         "application/json" => %Moonwalk.Spec.MediaType{
                           schema: %{"$ref" => "#/components/schemas/RecA"}
                         }
                       }
                     },
                     responses: _
                   }
                 },
                 "/p2" => %Moonwalk.Spec.PathItem{
                   post: %Moonwalk.Spec.Operation{
                     operationId: "op2",
                     requestBody: %Moonwalk.Spec.RequestBody{
                       content: %{
                         "application/json" => %Moonwalk.Spec.MediaType{
                           schema: %{"$ref" => "#/components/schemas/Moonwalk.SpecTest.MutualRecursiveB"}
                         }
                       }
                     },
                     responses: _
                   }
                 }
               }
             } =
               %{"paths" => schemas_to_paths([MutualRecursiveA, MutualRecursiveB])}
               |> base()
               |> Moonwalk.normalize_spec!()
               |> cast_to_structs()
    end

    defmodule PetSchema do
      import JSV

      defschema(%{
        title: "Pet",
        type: "object",
        properties: %{
          name: %{type: "string"},
          species: %{type: "string"}
        },
        required: [:name, :species]
      })
    end

    defmodule OccupationSchema do
      import JSV

      defschema(%{
        title: "Occupation",
        type: "object",
        properties: %{
          title: %{type: :string}
        },
        required: [:title]
      })
    end

    test "preexisting schemas in components" do
      # Base spec has a schema in the components, and an operation using another
      # schema with a title. Schema in components should remain there while the
      # other schema should be moved to components
      spec =
        %{
          "components" => %{
            "schemas" => %{
              "Person" => %{
                "title" => "Person",
                "type" => "object",
                "properties" => %{
                  "name" => %{"type" => "string"},
                  "age" => %{"type" => "integer"},
                  # Raw maps can contain module schemas
                  "occupation" => OccupationSchema
                },
                "required" => ["name"]
              }
            }
          },
          "paths" => schemas_to_paths([PetSchema])
        }
        |> base()
        |> Moonwalk.normalize_spec!()
        |> cast_to_structs()

      # the spec should have both the Person and Pet schemas
      assert %{
               components: %{
                 schemas: %{
                   "Person" => %{"title" => "Person"},
                   "Pet" => %{"title" => "Pet"},
                   "Occupation" => %{"title" => "Occupation"}
                 }
               }
             } = spec
    end

    defmodule IceCubeSchema do
      import JSV

      defschema(%{
        # Here the title is set to the predefined refname of the DrinkSchema. It
        # should not override the DrinkSchema, and will be incremented
        title: "SomeNameThatShouldNotChange",
        type: "object",
        properties: %{
          shape: %{enum: ["cube", "not actually a cube"]}
        },
        required: [:shape]
      })
    end

    defmodule DrinkSchema do
      import JSV

      defschema(%{
        title: "Drink",
        type: "object",
        properties: %{
          name: %{type: "string"},
          alcohol_degree: %{type: "integer"},
          ice: IceCubeSchema
        },
        required: [:name, :alcohol_degree]
      })
    end

    test "preexisting schemas in components with a module" do
      # In this case the components contain a module name. This should not
      # happen when reading specs from a JSON file but it can be defined at
      # the spec module level for some reason (if the user generates dynamic
      # references on compilation instead of using module names for instance).

      spec =
        %{
          "components" => %{
            "schemas" => %{
              # A module schema with a custom refname
              "SomeNameThatShouldNotChange" => DrinkSchema,
              # An atom schema that should not be reused if another schema
              # somewhere is also `false`.
              "SomethingWeDoNotWant" => false,
              "OtherStufNotEvenASchema" => "no problem"
            }
          },
          # Here we use false as an atom schema, should not be replaced by a
          # ref.
          "paths" =>
            schemas_to_paths([PetSchema, %{type: :object, properties: %{pet: PetSchema}, additionalProperties: false}])
        }
        |> base()
        |> Moonwalk.normalize_spec!()
        |> cast_to_structs()

      # the spec should have both the Person and Pet schemas
      assert %{
               components: %{
                 schemas: %{
                   "SomethingWeDoNotWant" => false,
                   "SomeNameThatShouldNotChange" => %{"title" => "Drink"},
                   # Module subschema was successfully added with an incremented
                   # refname.
                   "SomeNameThatShouldNotChange_1" => %{"title" => "SomeNameThatShouldNotChange"},
                   "Pet" => %{"title" => "Pet"},
                   "OtherStufNotEvenASchema" => "no problem"
                 }
               }
             } = spec
    end
  end

  describe "phoenix routes" do
    test "extracting operations from phoenix routes" do
      assert %Moonwalk.Spec.OpenAPI{
               paths: %{
                 "/generated/body/form" => %Moonwalk.Spec.PathItem{},
                 "/generated/body/inline-single" => %Moonwalk.Spec.PathItem{},
                 "/generated/body/module-single" => %Moonwalk.Spec.PathItem{},
                 "/generated/body/wildcard" => %Moonwalk.Spec.PathItem{},
                 "/generated/params/arrays" => %Moonwalk.Spec.PathItem{},
                 "/generated/params/generic" => %Moonwalk.Spec.PathItem{},
                 "/generated/params/s/{shape}" => %Moonwalk.Spec.PathItem{},
                 "/generated/params/s/{shape}/t/{theme}" => %Moonwalk.Spec.PathItem{},
                 "/generated/params/s/{shape}/t/{theme}/c/{color}" => %Moonwalk.Spec.PathItem{},
                 "/generated/params/t/{theme}" => %Moonwalk.Spec.PathItem{},
                 "/generated/params/t/{theme}/c/{color}" => %Moonwalk.Spec.PathItem{}
               }
             } =
               %{
                 :openapi => "3.1.1",
                 :info => %{"title" => "Moonwalk Test API", :version => "0.0.0"},
                 :paths => Paths.from_router(TestWeb.Router)
               }
               |> Moonwalk.normalize_spec!()
               |> cast_to_structs()
    end
  end

  IO.warn("""
  todo test that we can just pass an %Operation{} struct to the operation macro
  """)

  defp cast_to_structs(normal) do
    Moonwalk.Internal.SpecValidator.validate!(normal)
  end
end
