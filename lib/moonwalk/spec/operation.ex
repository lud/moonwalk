defmodule Moonwalk.Spec.Operation do
  alias Moonwalk.Spec.Parameter
  alias Moonwalk.Spec.RequestBody
  require JSV
  use Moonwalk.Spec

  # Describes a single API operation on a path.
  JSV.defschema(%{
    title: "Operation",
    type: :object,
    description: "Describes a single API operation on a path.",
    properties: %{
      tags: %{
        type: :array,
        items: %{type: :string},
        description: "A list of tags for API documentation control."
      },
      summary: %{type: :string, description: "A short summary of what the operation does."},
      description: %{
        type: :string,
        description: "A verbose explanation of the operation behavior."
      },
      externalDocs: Moonwalk.Spec.ExternalDocumentation,
      operationId: %{
        type: :string,
        description: "A unique string used to identify the operation."
      },
      parameters: %{
        type: :array,
        items: %{oneOf: [Moonwalk.Spec.Parameter, Moonwalk.Spec.Reference]},
        description: "A list of parameters applicable for this operation."
      },
      requestBody: %{oneOf: [Moonwalk.Spec.RequestBody, Moonwalk.Spec.Reference]},
      responses: Moonwalk.Spec.Responses,
      callbacks: %{
        type: :object,
        additionalProperties: %{oneOf: [Moonwalk.Spec.Callback, Moonwalk.Spec.Reference]},
        description: "A map of possible out-of-band callbacks related to the parent operation."
      },
      deprecated: %{type: :boolean, description: "Declares this operation to be deprecated."},
      security: %{
        type: :array,
        items: Moonwalk.Spec.SecurityRequirement,
        description: "A list of security mechanisms that can be used for this operation."
      },
      servers: %{
        type: :array,
        items: Moonwalk.Spec.Server,
        description: "Alternative servers array for this operation."
      }
    },
    required: [:responses]
  })

  IO.warn("TODO responses should always have at least one item")

  def from_controller!(spec) do
    spec
    |> make(__MODULE__)
    |> rename_input(:operation_id, :operationId)
    |> rename_input(:request_body, :requestBody)
    |> take_required(:operationId)
    |> take_default(:tags, [])
    |> take_default(:parameters, [], &cast_params/1)
    |> take_default(:description, nil)
    |> take_default(:responses, [])
    |> take_default(:summary, nil)
    |> take_default(
      :requestBody,
      nil,
      {&RequestBody.from_controller/1, "invalid request body"}
    )
    |> into()
  end

  defp cast_params(parameters) when is_map(parameters) do
    cast_params(Map.to_list(parameters))
  end

  defp cast_params(parameters) do
    if not Keyword.keyword?(parameters) do
      raise ArgumentError, "invalid parameters given to operation: #{inspect(parameters)}"
    end

    {:ok, Enum.map(parameters, fn {k, v} -> {k, Parameter.from_controller!(k, v)} end)}
  end
end
