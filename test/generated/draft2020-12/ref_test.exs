defmodule Elixir.Moonwalk.Generated.Draft202012.RefTest do
  alias Moonwalk.Test.JsonSchemaSuite
  use ExUnit.Case, async: true

  @moduledoc """
  Test generated from deps/json_schema_test_suite/tests/draft2020-12/ref.json
  """

  describe "root pointer ref ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "additionalProperties" => false,
        "properties" => %{"foo" => %{"$ref" => "#"}}
      }

      {:ok, schema: schema}
    end

    test "match", %{schema: schema} do
      data = %{"foo" => false}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "recursive match", %{schema: schema} do
      data = %{"foo" => %{"foo" => false}}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "mismatch", %{schema: schema} do
      data = %{"bar" => false}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "recursive mismatch", %{schema: schema} do
      data = %{"foo" => %{"bar" => false}}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "relative pointer ref to object ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{
          "bar" => %{"$ref" => "#/properties/foo"},
          "foo" => %{"type" => "integer"}
        }
      }

      {:ok, schema: schema}
    end

    test "match", %{schema: schema} do
      data = %{"bar" => 3}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "mismatch", %{schema: schema} do
      data = %{"bar" => true}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "relative pointer ref to array ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "prefixItems" => [%{"type" => "integer"}, %{"$ref" => "#/prefixItems/0"}]
      }

      {:ok, schema: schema}
    end

    test "match array", %{schema: schema} do
      data = [1, 2]
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "mismatch array", %{schema: schema} do
      data = [1, "foo"]
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "escaped pointer ref ⋅" do
    setup do
      schema = %{
        "$defs" => %{
          "percent%field" => %{"type" => "integer"},
          "slash/field" => %{"type" => "integer"},
          "tilde~field" => %{"type" => "integer"}
        },
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{
          "percent" => %{"$ref" => "#/$defs/percent%25field"},
          "slash" => %{"$ref" => "#/$defs/slash~1field"},
          "tilde" => %{"$ref" => "#/$defs/tilde~0field"}
        }
      }

      {:ok, schema: schema}
    end

    test "slash invalid", %{schema: schema} do
      data = %{"slash" => "aoeu"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "tilde invalid", %{schema: schema} do
      data = %{"tilde" => "aoeu"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "percent invalid", %{schema: schema} do
      data = %{"percent" => "aoeu"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "slash valid", %{schema: schema} do
      data = %{"slash" => 123}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "tilde valid", %{schema: schema} do
      data = %{"tilde" => 123}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "percent valid", %{schema: schema} do
      data = %{"percent" => 123}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "nested refs ⋅" do
    setup do
      schema = %{
        "$defs" => %{
          "a" => %{"type" => "integer"},
          "b" => %{"$ref" => "#/$defs/a"},
          "c" => %{"$ref" => "#/$defs/b"}
        },
        "$ref" => "#/$defs/c",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "nested ref valid", %{schema: schema} do
      data = 5
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "nested ref invalid", %{schema: schema} do
      data = "a"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "ref applies alongside sibling keywords ⋅" do
    setup do
      schema = %{
        "$defs" => %{"reffed" => %{"type" => "array"}},
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{"foo" => %{"$ref" => "#/$defs/reffed", "maxItems" => 2}}
      }

      {:ok, schema: schema}
    end

    test "ref valid, maxItems valid", %{schema: schema} do
      data = %{"foo" => []}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ref valid, maxItems invalid", %{schema: schema} do
      data = %{"foo" => [1, 2, 3]}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "ref invalid", %{schema: schema} do
      data = %{"foo" => "string"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "remote ref, containing refs itself ⋅" do
    setup do
      schema = %{
        "$ref" => "https://json-schema.org/draft/2020-12/schema",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "remote ref valid", %{schema: schema} do
      data = %{"minLength" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "remote ref invalid", %{schema: schema} do
      data = %{"minLength" => -1}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "property named $ref that is not a reference ⋅" do
    setup do
      schema = %{
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{"$ref" => %{"type" => "string"}}
      }

      {:ok, schema: schema}
    end

    test "property named $ref valid", %{schema: schema} do
      data = %{"$ref" => "a"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "property named $ref invalid", %{schema: schema} do
      data = %{"$ref" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "property named $ref, containing an actual $ref ⋅" do
    setup do
      schema = %{
        "$defs" => %{"is-string" => %{"type" => "string"}},
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{"$ref" => %{"$ref" => "#/$defs/is-string"}}
      }

      {:ok, schema: schema}
    end

    test "property named $ref valid", %{schema: schema} do
      data = %{"$ref" => "a"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "property named $ref invalid", %{schema: schema} do
      data = %{"$ref" => 2}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "$ref to boolean schema true ⋅" do
    setup do
      schema = %{
        "$defs" => %{"bool" => true},
        "$ref" => "#/$defs/bool",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "any value is valid", %{schema: schema} do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "$ref to boolean schema false ⋅" do
    setup do
      schema = %{
        "$defs" => %{"bool" => false},
        "$ref" => "#/$defs/bool",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "any value is invalid", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "Recursive references between schemas ⋅" do
    setup do
      schema = %{
        "$defs" => %{
          "node" => %{
            "$id" => "http://localhost:1234/draft2020-12/node",
            "description" => "node",
            "properties" => %{
              "subtree" => %{"$ref" => "tree"},
              "value" => %{"type" => "number"}
            },
            "required" => ["value"],
            "type" => "object"
          }
        },
        "$id" => "http://localhost:1234/draft2020-12/tree",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "description" => "tree of nodes",
        "properties" => %{
          "meta" => %{"type" => "string"},
          "nodes" => %{"items" => %{"$ref" => "node"}, "type" => "array"}
        },
        "required" => ["meta", "nodes"],
        "type" => "object"
      }

      {:ok, schema: schema}
    end

    test "valid tree", %{schema: schema} do
      data = %{
        "meta" => "root",
        "nodes" => [
          %{
            "subtree" => %{
              "meta" => "child",
              "nodes" => [%{"value" => 1.1}, %{"value" => 1.2}]
            },
            "value" => 1
          },
          %{
            "subtree" => %{
              "meta" => "child",
              "nodes" => [%{"value" => 2.1}, %{"value" => 2.2}]
            },
            "value" => 2
          }
        ]
      }

      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid tree", %{schema: schema} do
      data = %{
        "meta" => "root",
        "nodes" => [
          %{
            "subtree" => %{
              "meta" => "child",
              "nodes" => [%{"value" => "string is invalid"}, %{"value" => 1.2}]
            },
            "value" => 1
          },
          %{
            "subtree" => %{
              "meta" => "child",
              "nodes" => [%{"value" => 2.1}, %{"value" => 2.2}]
            },
            "value" => 2
          }
        ]
      }

      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "refs with quote ⋅" do
    setup do
      schema = %{
        "$defs" => %{"foo\"bar" => %{"type" => "number"}},
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{"foo\"bar" => %{"$ref" => "#/$defs/foo%22bar"}}
      }

      {:ok, schema: schema}
    end

    test "object with numbers is valid", %{schema: schema} do
      data = %{"foo\"bar" => 1}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "object with strings is invalid", %{schema: schema} do
      data = %{"foo\"bar" => "1"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "ref creates new scope when adjacent to keywords ⋅" do
    setup do
      schema = %{
        "$defs" => %{"A" => %{"unevaluatedProperties" => false}},
        "$ref" => "#/$defs/A",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{"prop1" => %{"type" => "string"}}
      }

      {:ok, schema: schema}
    end

    @tag :skip
    test "referenced subschema doesn't see annotations from properties", %{schema: schema} do
      data = %{"prop1" => "match"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "naive replacement of $ref with its destination is not correct ⋅" do
    setup do
      schema = %{
        "$defs" => %{"a_string" => %{"type" => "string"}},
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "enum" => [%{"$ref" => "#/$defs/a_string"}]
      }

      {:ok, schema: schema}
    end

    test "do not evaluate the $ref inside the enum, matching any string", %{schema: schema} do
      data = "this is a string"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "do not evaluate the $ref inside the enum, definition exact match", %{schema: schema} do
      data = %{"type" => "string"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "match the enum exactly", %{schema: schema} do
      data = %{"$ref" => "#/$defs/a_string"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "refs with relative uris and defs ⋅" do
    setup do
      schema = %{
        "$id" => "http://example.com/schema-relative-uri-defs1.json",
        "$ref" => "schema-relative-uri-defs2.json",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{
          "foo" => %{
            "$defs" => %{
              "inner" => %{"properties" => %{"bar" => %{"type" => "string"}}}
            },
            "$id" => "schema-relative-uri-defs2.json",
            "$ref" => "#/$defs/inner"
          }
        }
      }

      {:ok, schema: schema}
    end

    test "invalid on inner field", %{schema: schema} do
      data = %{"bar" => "a", "foo" => %{"bar" => 1}}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid on outer field", %{schema: schema} do
      data = %{"bar" => 1, "foo" => %{"bar" => "a"}}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "valid on both fields", %{schema: schema} do
      data = %{"bar" => "a", "foo" => %{"bar" => "a"}}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "relative refs with absolute uris and defs ⋅" do
    setup do
      schema = %{
        "$id" => "http://example.com/schema-refs-absolute-uris-defs1.json",
        "$ref" => "schema-refs-absolute-uris-defs2.json",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{
          "foo" => %{
            "$defs" => %{
              "inner" => %{"properties" => %{"bar" => %{"type" => "string"}}}
            },
            "$id" => "http://example.com/schema-refs-absolute-uris-defs2.json",
            "$ref" => "#/$defs/inner"
          }
        }
      }

      {:ok, schema: schema}
    end

    test "invalid on inner field", %{schema: schema} do
      data = %{"bar" => "a", "foo" => %{"bar" => 1}}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid on outer field", %{schema: schema} do
      data = %{"bar" => 1, "foo" => %{"bar" => "a"}}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "valid on both fields", %{schema: schema} do
      data = %{"bar" => "a", "foo" => %{"bar" => "a"}}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "$id must be resolved against nearest parent, not just immediate parent ⋅" do
    setup do
      schema = %{
        "$defs" => %{
          "x" => %{
            "$id" => "http://example.com/b/c.json",
            "not" => %{"$defs" => %{"y" => %{"$id" => "d.json", "type" => "number"}}}
          }
        },
        "$id" => "http://example.com/a.json",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [%{"$ref" => "http://example.com/b/d.json"}]
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

  describe "order of evaluation: $id and $ref ⋅" do
    setup do
      schema = %{
        "$comment" => "$id must be evaluated before $ref to get the proper $ref destination",
        "$defs" => %{
          "bigint" => %{
            "$comment" => "canonical uri: https://example.com/ref-and-id1/int.json",
            "$id" => "int.json",
            "maximum" => 10
          },
          "smallint" => %{
            "$comment" => "canonical uri: https://example.com/ref-and-id1-int.json",
            "$id" => "/draft2020-12/ref-and-id1-int.json",
            "maximum" => 2
          }
        },
        "$id" => "https://example.com/draft2020-12/ref-and-id1/base.json",
        "$ref" => "int.json",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "data is valid against first definition", %{schema: schema} do
      data = 5
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "data is invalid against first definition", %{schema: schema} do
      data = 50
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "order of evaluation: $id and $anchor and $ref ⋅" do
    setup do
      schema = %{
        "$comment" => "$id must be evaluated before $ref to get the proper $ref destination",
        "$defs" => %{
          "bigint" => %{
            "$anchor" => "bigint",
            "$comment" =>
              "canonical uri: /ref-and-id2/base.json#/$defs/bigint; another valid uri for this location: /ref-and-id2/base.json#bigint",
            "maximum" => 10
          },
          "smallint" => %{
            "$anchor" => "bigint",
            "$comment" =>
              "canonical uri: https://example.com/ref-and-id2#/$defs/smallint; another valid uri for this location: https://example.com/ref-and-id2/#bigint",
            "$id" => "https://example.com/draft2020-12/ref-and-id2/",
            "maximum" => 2
          }
        },
        "$id" => "https://example.com/draft2020-12/ref-and-id2/base.json",
        "$ref" => "#bigint",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "data is valid against first definition", %{schema: schema} do
      data = 5
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "data is invalid against first definition", %{schema: schema} do
      data = 50
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "simple URN base URI with $ref via the URN ⋅" do
    setup do
      schema = %{
        "$comment" => "URIs do not have to have HTTP(s) schemes",
        "$id" => "urn:uuid:deadbeef-1234-ffff-ffff-4321feebdaed",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "minimum" => 30,
        "properties" => %{
          "foo" => %{"$ref" => "urn:uuid:deadbeef-1234-ffff-ffff-4321feebdaed"}
        }
      }

      {:ok, schema: schema}
    end

    test "valid under the URN IDed schema", %{schema: schema} do
      data = %{"foo" => 37}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "invalid under the URN IDed schema", %{schema: schema} do
      data = %{"foo" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "simple URN base URI with JSON pointer ⋅" do
    setup do
      schema = %{
        "$comment" => "URIs do not have to have HTTP(s) schemes",
        "$defs" => %{"bar" => %{"type" => "string"}},
        "$id" => "urn:uuid:deadbeef-1234-00ff-ff00-4321feebdaed",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{"foo" => %{"$ref" => "#/$defs/bar"}}
      }

      {:ok, schema: schema}
    end

    test "a string is valid", %{schema: schema} do
      data = %{"foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a non-string is invalid", %{schema: schema} do
      data = %{"foo" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "URN base URI with NSS ⋅" do
    setup do
      schema = %{
        "$comment" => "RFC 8141 §2.2",
        "$defs" => %{"bar" => %{"type" => "string"}},
        "$id" => "urn:example:1/406/47452/2",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{"foo" => %{"$ref" => "#/$defs/bar"}}
      }

      {:ok, schema: schema}
    end

    test "a string is valid", %{schema: schema} do
      data = %{"foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a non-string is invalid", %{schema: schema} do
      data = %{"foo" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "URN base URI with r-component ⋅" do
    setup do
      schema = %{
        "$comment" => "RFC 8141 §2.3.1",
        "$defs" => %{"bar" => %{"type" => "string"}},
        "$id" => "urn:example:foo-bar-baz-qux?+CCResolve:cc=uk",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{"foo" => %{"$ref" => "#/$defs/bar"}}
      }

      {:ok, schema: schema}
    end

    test "a string is valid", %{schema: schema} do
      data = %{"foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a non-string is invalid", %{schema: schema} do
      data = %{"foo" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "URN base URI with q-component ⋅" do
    setup do
      schema = %{
        "$comment" => "RFC 8141 §2.3.2",
        "$defs" => %{"bar" => %{"type" => "string"}},
        "$id" => "urn:example:weather?=op=map&lat=39.56&lon=-104.85&datetime=1969-07-21T02:56:15Z",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{"foo" => %{"$ref" => "#/$defs/bar"}}
      }

      {:ok, schema: schema}
    end

    test "a string is valid", %{schema: schema} do
      data = %{"foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a non-string is invalid", %{schema: schema} do
      data = %{"foo" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "URN base URI with f-component ⋅" do
    setup do
      schema = %{
        "$comment" => "RFC 8141 §2.3.3, but we don't allow fragments",
        "$ref" => "https://json-schema.org/draft/2020-12/schema",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "is invalid", %{schema: schema} do
      data = %{"$id" => "urn:example:foo-bar-baz-qux#somepart"}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "URN base URI with URN and JSON pointer ref ⋅" do
    setup do
      schema = %{
        "$defs" => %{"bar" => %{"type" => "string"}},
        "$id" => "urn:uuid:deadbeef-1234-0000-0000-4321feebdaed",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{
          "foo" => %{
            "$ref" => "urn:uuid:deadbeef-1234-0000-0000-4321feebdaed#/$defs/bar"
          }
        }
      }

      {:ok, schema: schema}
    end

    test "a string is valid", %{schema: schema} do
      data = %{"foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a non-string is invalid", %{schema: schema} do
      data = %{"foo" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "URN base URI with URN and anchor ref ⋅" do
    setup do
      schema = %{
        "$defs" => %{"bar" => %{"$anchor" => "something", "type" => "string"}},
        "$id" => "urn:uuid:deadbeef-1234-ff00-00ff-4321feebdaed",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "properties" => %{
          "foo" => %{
            "$ref" => "urn:uuid:deadbeef-1234-ff00-00ff-4321feebdaed#something"
          }
        }
      }

      {:ok, schema: schema}
    end

    test "a string is valid", %{schema: schema} do
      data = %{"foo" => "bar"}
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a non-string is invalid", %{schema: schema} do
      data = %{"foo" => 12}
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "URN ref with nested pointer ref ⋅" do
    setup do
      schema = %{
        "$defs" => %{
          "foo" => %{
            "$defs" => %{"bar" => %{"type" => "string"}},
            "$id" => "urn:uuid:deadbeef-4321-ffff-ffff-1234feebdaed",
            "$ref" => "#/$defs/bar"
          }
        },
        "$ref" => "urn:uuid:deadbeef-4321-ffff-ffff-1234feebdaed",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "a string is valid", %{schema: schema} do
      data = "bar"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "a non-string is invalid", %{schema: schema} do
      data = 12
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "ref to if ⋅" do
    setup do
      schema = %{
        "$ref" => "http://example.com/ref/if",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "if" => %{"$id" => "http://example.com/ref/if", "type" => "integer"}
      }

      {:ok, schema: schema}
    end

    test "a non-integer is invalid due to the $ref", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an integer is valid", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "ref to then ⋅" do
    setup do
      schema = %{
        "$ref" => "http://example.com/ref/then",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "then" => %{"$id" => "http://example.com/ref/then", "type" => "integer"}
      }

      {:ok, schema: schema}
    end

    test "a non-integer is invalid due to the $ref", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an integer is valid", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "ref to else ⋅" do
    setup do
      schema = %{
        "$ref" => "http://example.com/ref/else",
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "else" => %{"$id" => "http://example.com/ref/else", "type" => "integer"}
      }

      {:ok, schema: schema}
    end

    test "a non-integer is invalid due to the $ref", %{schema: schema} do
      data = "foo"
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an integer is valid", %{schema: schema} do
      data = 12
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "ref with absolute-path-reference ⋅" do
    setup do
      schema = %{
        "$defs" => %{
          "a" => %{
            "$id" => "http://example.com/ref/absref/foobar.json",
            "type" => "number"
          },
          "b" => %{
            "$id" => "http://example.com/absref/foobar.json",
            "type" => "string"
          }
        },
        "$id" => "http://example.com/ref/absref.json",
        "$ref" => "/absref/foobar.json",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
      }

      {:ok, schema: schema}
    end

    test "a string is valid", %{schema: schema} do
      data = "foo"
      expected_valid = true
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end

    test "an integer is invalid", %{schema: schema} do
      data = 12
      expected_valid = false
      JsonSchemaSuite.run_test(schema, data, expected_valid)
    end
  end

  describe "$id with file URI still resolves pointers - *nix ⋅" do
    setup do
      schema = %{
        "$defs" => %{"foo" => %{"type" => "number"}},
        "$id" => "file:///folder/file.json",
        "$ref" => "#/$defs/foo",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
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

  describe "$id with file URI still resolves pointers - windows ⋅" do
    setup do
      schema = %{
        "$defs" => %{"foo" => %{"type" => "number"}},
        "$id" => "file:///c:/folder/file.json",
        "$ref" => "#/$defs/foo",
        "$schema" => "https://json-schema.org/draft/2020-12/schema"
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

  describe "empty tokens in $ref json-pointer ⋅" do
    setup do
      schema = %{
        "$defs" => %{"" => %{"$defs" => %{"" => %{"type" => "number"}}}},
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "allOf" => [%{"$ref" => "#/$defs//$defs/"}]
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
end
