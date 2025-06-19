defmodule Moonwalk.TestWeb.DeclarativeApiSpec do
  use Moonwalk
  require JSV

  IO.warn("todo add another route that uses strucs all the way down, including %Reference{}")

  defmodule Ingredient do
    JSV.defschema(%{
      "type" => "object",
      "properties" => %{
        name: %{"type" => "string"},
        quantity: %{"type" => "integer"},
        unit: %{
          "type" => "string",
          "enum" => ["pinch", "dash", "scoop", "whiff", "nub"]
        }
      },
      "required" => [:name, :quantity, :unit]
    })
  end

  defmodule CreatePotionBody do
    JSV.defschema(%{
      "type" => "object",
      "properties" => %{
        name: %{"type" => "string"},
        ingredients: %{
          "type" => "array",
          "items" => %{"$ref" => "#/components/schemas/Ingredient"}
        }
      },
      "required" => [:name, :ingredients]
    })
  end

  defmodule Potion do
    JSV.defschema(%{
      "type" => "object",
      "properties" => %{
        id: %{"type" => "string"},
        name: %{"type" => "string"},
        ingredients: %{
          "type" => "array",
          "items" => %{"$ref" => "#/components/schemas/Ingredient"}
        },
        brewingTime: %{"type" => "integer"}
      },
      "required" => [:id, :name, :ingredients]
    })
  end

  IO.warn("@todo test parameters at the path level")
  IO.warn("@todo test responses schemas")

  @api_spec %{
    "openapi" => "3.1.0",
    "info" => %{
      "title" => "Alchemy Lab API",
      "version" => "1.0.0"
    },
    "paths" => %{
      "/potions" => %{"$ref" => "#/components/pathItems/CreatePotionPath"}
    },
    "components" => %{
      "pathItems" => %{
        "CreatePotionPath" => %{
          "post" => %{
            "operationId" => "createPotion",
            "parameters" => [
              %{"$ref" => "#/components/parameters/DryRun"},
              %{"$ref" => "#/components/parameters/Source"}
            ],
            "requestBody" => %{"$ref" => "#/components/requestBodies/CreatePotionRequest"},
            "responses" => %{
              "200" => %{"$ref" => "#/components/responses/PotionCreated"}
            }
          }
        }
      },
      "parameters" => %{
        "DryRun" => %{
          "name" => "dry_run",
          "in" => "query",
          "schema" => %{"type" => "boolean"}
        },
        "Source" => %{
          "name" => "source",
          "in" => "query",
          "schema" => %{"type" => "string"}
        }
      },
      "requestBodies" => %{
        "CreatePotionRequest" => %{
          "required" => true,
          "content" => %{
            "application/json" => %{
              "schema" => %{"$ref" => "#/components/schemas/CreatePotionBody"}
            }
          }
        }
      },
      "responses" => %{
        "PotionCreated" => %{
          "description" => "Potion created successfully",
          "content" => %{
            "application/json" => %{
              "schema" => %{"$ref" => "#/components/schemas/Potion"}
            }
          }
        }
      },
      "schemas" => %{
        "Ingredient" => Ingredient,
        "CreatePotionBody" => CreatePotionBody,
        "Potion" => Potion
      }
    }
  }

  def spec do
    @api_spec
  end
end
