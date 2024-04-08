defmodule Elixir.Moonwalk.Generated.Draft202012.DynamicRefTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  describe "A $dynamicRef to a $dynamicAnchor in the same schema resource behaves like a normal $ref to an $anchor" do
    setup do
      schema = %{
        "$defs" => %{"foo" => %{"$dynamicAnchor" => "items", "type" => "string"}},
        "$id" => "https://test.json-schema.org/dynamicRef-dynamicAnchor-same-schema/root",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "items" => %{"$dynamicRef" => "#items"},
        "type" => "array"
      }

      {:ok, schema: schema}
    end

    test "An array of strings is valid", %{schema: schema} do
      data = ["foo", "bar"]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "An array containing non-strings is invalid", %{schema: schema} do
      data = ["foo", 42]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "A $dynamicRef to an $anchor in the same schema resource behaves like a normal $ref to an $anchor" do
    setup do
      schema = %{
        "$defs" => %{"foo" => %{"$anchor" => "items", "type" => "string"}},
        "$id" => "https://test.json-schema.org/dynamicRef-anchor-same-schema/root",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "items" => %{"$dynamicRef" => "#items"},
        "type" => "array"
      }

      {:ok, schema: schema}
    end

    test "An array of strings is valid", %{schema: schema} do
      data = ["foo", "bar"]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "An array containing non-strings is invalid", %{schema: schema} do
      data = ["foo", 42]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "A $ref to a $dynamicAnchor in the same schema resource behaves like a normal $ref to an $anchor" do
    setup do
      schema = %{
        "$defs" => %{"foo" => %{"$dynamicAnchor" => "items", "type" => "string"}},
        "$id" => "https://test.json-schema.org/ref-dynamicAnchor-same-schema/root",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "items" => %{"$ref" => "#items"},
        "type" => "array"
      }

      {:ok, schema: schema}
    end

    test "An array of strings is valid", %{schema: schema} do
      data = ["foo", "bar"]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "An array containing non-strings is invalid", %{schema: schema} do
      data = ["foo", 42]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "A $dynamicRef resolves to the first $dynamicAnchor still in scope that is encountered when the schema is evaluated" do
    setup do
      schema = %{
        "$defs" => %{
          "foo" => %{"$dynamicAnchor" => "items", "type" => "string"},
          "list" => %{
            "$defs" => %{
              "items" => %{
                "$comment" => "This is only needed to satisfy the bookending requirement",
                "$dynamicAnchor" => "items"
              }
            },
            "$id" => "list",
            "items" => %{"$dynamicRef" => "#items"},
            "type" => "array"
          }
        },
        "$id" => "https://test.json-schema.org/typical-dynamic-resolution/root",
        "$ref" => "list",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "An array of strings is valid", %{schema: schema} do
      data = ["foo", "bar"]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "An array containing non-strings is invalid", %{schema: schema} do
      data = ["foo", 42]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "A $dynamicRef without anchor in fragment behaves identical to $ref" do
    setup do
      schema = %{
        "$defs" => %{
          "foo" => %{"$dynamicAnchor" => "items", "type" => "string"},
          "list" => %{
            "$defs" => %{
              "items" => %{
                "$comment" => "This is only needed to satisfy the bookending requirement",
                "$dynamicAnchor" => "items",
                "type" => "number"
              }
            },
            "$id" => "list",
            "items" => %{"$dynamicRef" => "#/$defs/items"},
            "type" => "array"
          }
        },
        "$id" => "https://test.json-schema.org/dynamicRef-without-anchor/root",
        "$ref" => "list",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "An array of strings is invalid", %{schema: schema} do
      data = ["foo", "bar"]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "An array of numbers is valid", %{schema: schema} do
      data = [24, 42]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "A $dynamicRef with intermediate scopes that don't include a matching $dynamicAnchor does not affect dynamic scope resolution" do
    setup do
      schema = %{
        "$defs" => %{
          "foo" => %{"$dynamicAnchor" => "items", "type" => "string"},
          "intermediate-scope" => %{"$id" => "intermediate-scope", "$ref" => "list"},
          "list" => %{
            "$defs" => %{
              "items" => %{
                "$comment" => "This is only needed to satisfy the bookending requirement",
                "$dynamicAnchor" => "items"
              }
            },
            "$id" => "list",
            "items" => %{"$dynamicRef" => "#items"},
            "type" => "array"
          }
        },
        "$id" => "https://test.json-schema.org/dynamic-resolution-with-intermediate-scopes/root",
        "$ref" => "intermediate-scope",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "An array of strings is valid", %{schema: schema} do
      data = ["foo", "bar"]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "An array containing non-strings is invalid", %{schema: schema} do
      data = ["foo", 42]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "An $anchor with the same name as a $dynamicAnchor is not used for dynamic scope resolution" do
    setup do
      schema = %{
        "$defs" => %{
          "foo" => %{"$anchor" => "items", "type" => "string"},
          "list" => %{
            "$defs" => %{
              "items" => %{
                "$comment" => "This is only needed to satisfy the bookending requirement",
                "$dynamicAnchor" => "items"
              }
            },
            "$id" => "list",
            "items" => %{"$dynamicRef" => "#items"},
            "type" => "array"
          }
        },
        "$id" => "https://test.json-schema.org/dynamic-resolution-ignores-anchors/root",
        "$ref" => "list",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "Any array is valid", %{schema: schema} do
      data = ["foo", 42]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "A $dynamicRef without a matching $dynamicAnchor in the same schema resource behaves like a normal $ref to $anchor" do
    setup do
      schema = %{
        "$defs" => %{
          "foo" => %{"$dynamicAnchor" => "items", "type" => "string"},
          "list" => %{
            "$defs" => %{
              "items" => %{
                "$anchor" => "items",
                "$comment" =>
                  "This is only needed to give the reference somewhere to resolve to when it behaves like $ref"
              }
            },
            "$id" => "list",
            "items" => %{"$dynamicRef" => "#items"},
            "type" => "array"
          }
        },
        "$id" => "https://test.json-schema.org/dynamic-resolution-without-bookend/root",
        "$ref" => "list",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "Any array is valid", %{schema: schema} do
      data = ["foo", 42]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "A $dynamicRef with a non-matching $dynamicAnchor in the same schema resource behaves like a normal $ref to $anchor" do
    setup do
      schema = %{
        "$defs" => %{
          "foo" => %{"$dynamicAnchor" => "items", "type" => "string"},
          "list" => %{
            "$defs" => %{
              "items" => %{
                "$anchor" => "items",
                "$comment" =>
                  "This is only needed to give the reference somewhere to resolve to when it behaves like $ref",
                "$dynamicAnchor" => "foo"
              }
            },
            "$id" => "list",
            "items" => %{"$dynamicRef" => "#items"},
            "type" => "array"
          }
        },
        "$id" => "https://test.json-schema.org/unmatched-dynamic-anchor/root",
        "$ref" => "list",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "Any array is valid", %{schema: schema} do
      data = ["foo", 42]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "A $dynamicRef that initially resolves to a schema with a matching $dynamicAnchor resolves to the first $dynamicAnchor in the dynamic scope" do
    setup do
      schema = %{
        "$defs" => %{
          "bar" => %{
            "$id" => "bar",
            "properties" => %{"baz" => %{"$dynamicRef" => "extended#meta"}},
            "type" => "object"
          },
          "extended" => %{
            "$dynamicAnchor" => "meta",
            "$id" => "extended",
            "properties" => %{"bar" => %{"$ref" => "bar"}},
            "type" => "object"
          }
        },
        "$dynamicAnchor" => "meta",
        "$id" => "https://test.json-schema.org/relative-dynamic-reference/root",
        "$ref" => "extended",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{"foo" => %{"const" => "pass"}},
        "type" => "object"
      }

      {:ok, schema: schema}
    end

    test "The recursive part is valid against the root", %{schema: schema} do
      data = %{"bar" => %{"baz" => %{"foo" => "pass"}}, "foo" => "pass"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "The recursive part is not valid against the root", %{schema: schema} do
      data = %{"bar" => %{"baz" => %{"foo" => "fail"}}, "foo" => "pass"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "A $dynamicRef that initially resolves to a schema without a matching $dynamicAnchor behaves like a normal $ref to $anchor" do
    setup do
      schema = %{
        "$defs" => %{
          "bar" => %{
            "$id" => "bar",
            "properties" => %{"baz" => %{"$dynamicRef" => "extended#meta"}},
            "type" => "object"
          },
          "extended" => %{
            "$anchor" => "meta",
            "$id" => "extended",
            "properties" => %{"bar" => %{"$ref" => "bar"}},
            "type" => "object"
          }
        },
        "$dynamicAnchor" => "meta",
        "$id" => "https://test.json-schema.org/relative-dynamic-reference-without-bookend/root",
        "$ref" => "extended",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{"foo" => %{"const" => "pass"}},
        "type" => "object"
      }

      {:ok, schema: schema}
    end

    test "The recursive part doesn't need to validate against the root", %{schema: schema} do
      data = %{"bar" => %{"baz" => %{"foo" => "fail"}}, "foo" => "pass"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "multiple dynamic paths to the $dynamicRef keyword" do
    setup do
      schema = %{
        "$defs" => %{
          "genericList" => %{
            "$defs" => %{
              "defaultItemType" => %{
                "$comment" => "Only needed to satisfy bookending requirement",
                "$dynamicAnchor" => "itemType"
              }
            },
            "$id" => "genericList",
            "properties" => %{"list" => %{"items" => %{"$dynamicRef" => "#itemType"}}}
          },
          "numberList" => %{
            "$defs" => %{
              "itemType" => %{"$dynamicAnchor" => "itemType", "type" => "number"}
            },
            "$id" => "numberList",
            "$ref" => "genericList"
          },
          "stringList" => %{
            "$defs" => %{
              "itemType" => %{"$dynamicAnchor" => "itemType", "type" => "string"}
            },
            "$id" => "stringList",
            "$ref" => "genericList"
          }
        },
        "$id" => "https://test.json-schema.org/dynamic-ref-with-multiple-paths/main",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "else" => %{"$ref" => "stringList"},
        "if" => %{
          "properties" => %{"kindOfList" => %{"const" => "numbers"}},
          "required" => ["kindOfList"]
        },
        "then" => %{"$ref" => "numberList"}
      }

      {:ok, schema: schema}
    end

    test "number list with number values", %{schema: schema} do
      data = %{"kindOfList" => "numbers", "list" => [1.1]}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "number list with string values", %{schema: schema} do
      data = %{"kindOfList" => "numbers", "list" => ["foo"]}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "string list with number values", %{schema: schema} do
      data = %{"kindOfList" => "strings", "list" => [1.1]}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "string list with string values", %{schema: schema} do
      data = %{"kindOfList" => "strings", "list" => ["foo"]}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "after leaving a dynamic scope, it is not used by a $dynamicRef" do
    setup do
      schema = %{
        "$defs" => %{
          "start" => %{
            "$comment" => "this is the landing spot from $ref",
            "$dynamicRef" => "inner_scope#thingy",
            "$id" => "start"
          },
          "thingy" => %{
            "$comment" => "this is the first stop for the $dynamicRef",
            "$dynamicAnchor" => "thingy",
            "$id" => "inner_scope",
            "type" => "string"
          }
        },
        "$id" => "https://test.json-schema.org/dynamic-ref-leaving-dynamic-scope/main",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "if" => %{
          "$defs" => %{
            "thingy" => %{
              "$comment" => "this is first_scope#thingy",
              "$dynamicAnchor" => "thingy",
              "type" => "number"
            }
          },
          "$id" => "first_scope"
        },
        "then" => %{
          "$defs" => %{
            "thingy" => %{
              "$comment" => "this is second_scope#thingy, the final destination of the $dynamicRef",
              "$dynamicAnchor" => "thingy",
              "type" => "null"
            }
          },
          "$id" => "second_scope",
          "$ref" => "start"
        }
      }

      {:ok, schema: schema}
    end

    test "string matches /$defs/thingy, but the $dynamicRef does not stop here", %{schema: schema} do
      data = "a string"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "first_scope is not in dynamic scope for the $dynamicRef", %{schema: schema} do
      data = 42
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "/then/$defs/thingy is the final stop for the $dynamicRef", %{schema: schema} do
      data = nil
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "strict-tree schema, guards against misspelled properties" do
    setup do
      schema = %{
        "$dynamicAnchor" => "node",
        "$id" => "http://localhost:1234/draft2020-12/strict-tree.json",
        "$ref" => "tree.json",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "unevaluatedProperties" => false
      }

      {:ok, schema: schema}
    end

    @tag :skip
    test "instance with misspelled field", %{schema: schema} do
      data = %{"children" => [%{"daat" => 1}]}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    @tag :skip
    test "instance with correct field", %{schema: schema} do
      data = %{"children" => [%{"data" => 1}]}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "tests for implementation dynamic anchor and reference link" do
    setup do
      schema = %{
        "$defs" => %{
          "elements" => %{
            "$dynamicAnchor" => "elements",
            "additionalProperties" => false,
            "properties" => %{"a" => true},
            "required" => ["a"]
          }
        },
        "$id" => "http://localhost:1234/draft2020-12/strict-extendible.json",
        "$ref" => "extendible-dynamic-ref.json",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "incorrect parent schema", %{schema: schema} do
      data = %{"a" => true}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "incorrect extended schema", %{schema: schema} do
      data = %{"elements" => [%{"b" => 1}]}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "correct extended schema", %{schema: schema} do
      data = %{"elements" => [%{"a" => 1}]}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "$ref and $dynamicAnchor are independent of order - $defs first" do
    setup do
      schema = %{
        "$id" => "http://localhost:1234/draft2020-12/strict-extendible-allof-defs-first.json",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [
          %{"$ref" => "extendible-dynamic-ref.json"},
          %{
            "$defs" => %{
              "elements" => %{
                "$dynamicAnchor" => "elements",
                "additionalProperties" => false,
                "properties" => %{"a" => true},
                "required" => ["a"]
              }
            }
          }
        ]
      }

      {:ok, schema: schema}
    end

    test "incorrect parent schema", %{schema: schema} do
      data = %{"a" => true}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "incorrect extended schema", %{schema: schema} do
      data = %{"elements" => [%{"b" => 1}]}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "correct extended schema", %{schema: schema} do
      data = %{"elements" => [%{"a" => 1}]}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "$ref and $dynamicAnchor are independent of order - $ref first" do
    setup do
      schema = %{
        "$id" => "http://localhost:1234/draft2020-12/strict-extendible-allof-ref-first.json",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [
          %{
            "$defs" => %{
              "elements" => %{
                "$dynamicAnchor" => "elements",
                "additionalProperties" => false,
                "properties" => %{"a" => true},
                "required" => ["a"]
              }
            }
          },
          %{"$ref" => "extendible-dynamic-ref.json"}
        ]
      }

      {:ok, schema: schema}
    end

    test "incorrect parent schema", %{schema: schema} do
      data = %{"a" => true}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "incorrect extended schema", %{schema: schema} do
      data = %{"elements" => [%{"b" => 1}]}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "correct extended schema", %{schema: schema} do
      data = %{"elements" => [%{"a" => 1}]}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "$ref to $dynamicRef finds detached $dynamicAnchor" do
    setup do
      schema = %{
        "$ref" => "http://localhost:1234/draft2020-12/detached-dynamicref.json#/$defs/foo"
      }

      {:ok, schema: schema}
    end

    test "number is valid", %{schema: schema} do
      data = 1
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "non-number is invalid", %{schema: schema} do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "$dynamicRef points to a boolean schema" do
    setup do
      schema = %{
        "$defs" => %{"false" => false, "true" => true},
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{
          "false" => %{"$dynamicRef" => "#/$defs/false"},
          "true" => %{"$dynamicRef" => "#/$defs/true"}
        }
      }

      {:ok, schema: schema}
    end

    test "follow $dynamicRef to a true schema", %{schema: schema} do
      data = %{"true" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "follow $dynamicRef to a false schema", %{schema: schema} do
      data = %{"false" => 1}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end
end
