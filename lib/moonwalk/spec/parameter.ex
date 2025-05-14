defmodule Moonwalk.Spec.Parameter do
  require JSV
  use Moonwalk.Spec

  # Describes a single operation parameter.
  JSV.defschema(%{
    title: "Parameter",
    type: :object,
    description: "Describes a single operation parameter.",
    properties: %{
      name: %{
        type: :string,
        description: "The name of the parameter. Required."
      },
      in:
        JSV.Schema.string_to_atom_enum(
          %{
            description:
              "The location of the parameter. Allowed values: query, header, path, cookie. Required."
          },
          [
            :query,
            :header,
            :path,
            :cookie
          ]
        ),
      description: %{type: :string, description: "A brief description of the parameter."},
      required: %{type: :boolean, description: "Determines whether this parameter is mandatory."},
      deprecated: %{type: :boolean, description: "Specifies that the parameter is deprecated."},
      # allowEmptyValue: %{
      #   type: :boolean,
      #   description: "Sets the ability to pass empty-valued parameters."
      # },
      # style:
      #   JSV.Schema.string_to_atom_enum(
      #     %{
      #       description:
      #         "Describes how the parameter value will be serialized. See OpenAPI spec for allowed values."
      #     },
      #     [
      #       :matrix,
      #       :label,
      #       :form,
      #       :simple,
      #       :spaceDelimited,
      #       :pipeDelimited,
      #       :deepObject
      #     ]
      #   ),
      # explode: %{
      #   type: :boolean,
      #   description: "When true, array or object values generate separate parameters."
      # },
      # allowReserved: %{
      #   type: :boolean,
      #   description: "Allows reserved characters in parameter values."
      # },
      schema: %{oneOf: [Moonwalk.Spec.SchemaWrapper, Moonwalk.Spec.Reference]},
      examples: %{
        type: :object,
        additionalProperties: %{oneOf: [Moonwalk.Spec.Example, Moonwalk.Spec.Reference]},
        description: "Examples of the parameter's potential value."
      }
      # content: %{
      #   type: :object,
      #   additionalProperties: Moonwalk.Spec.MediaType,
      #   description: "A map containing parameter representations for different media types."
      # }
    },
    required: [:name, :in]
  })

  def from_controller!(name, spec) when is_atom(name) and is_list(spec) do
    default_examples =
      case Access.fetch(spec, :example) do
        {:ok, example} -> [example]
        :error -> []
      end

    default_required = Access.fetch(spec, :in) == {:ok, :path}

    spec
    |> make(__MODULE__)
    |> put(:name, name)
    |> take_required(:in, &validate_location/1)
    |> take_default(:schema, _boolean_schema = true)
    |> take_default(:required, default_required)
    |> take_default(:examples, default_examples)
    |> into()
  end

  defp validate_location(loc) do
    if loc in [:path, :query] do
      {:ok, loc}
    else
      {:error, "parameter :in only supports :path and :query"}
    end
  end
end
