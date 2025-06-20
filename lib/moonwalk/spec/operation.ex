defmodule Moonwalk.Spec.Operation do
  alias Moonwalk.Spec.Parameter
  alias Moonwalk.Spec.RequestBody
  alias Moonwalk.Spec.Response
  import Moonwalk.Internal.ControllerBuilder
  require JSV
  use Moonwalk.Internal.SpecObject

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
        items: %{anyOf: [Moonwalk.Spec.Reference, Moonwalk.Spec.Parameter]},
        description: "A list of parameters applicable for this operation."
      },
      requestBody: %{anyOf: [Moonwalk.Spec.Reference, Moonwalk.Spec.RequestBody]},
      responses: Moonwalk.Spec.Responses,
      callbacks: %{
        type: :object,
        additionalProperties: %{anyOf: [Moonwalk.Spec.Reference, Moonwalk.Spec.Callback]},
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
    required: [:responses, :operationId]
  })

  IO.warn("TODO responses should always have at least one item")

  @impl true
  def normalize!(data, ctx) do
    data
    |> make(__MODULE__, ctx)
    |> normalize_default([:tags, :summary, :description, :operationId, :deprecated])
    |> normalize_subs(
      requestBody: {:or_ref, Moonwalk.Spec.RequestBody},
      externalDocs: Moonwalk.Spec.ExternalDocumentation,
      parameters: {:list, {:or_ref, Moonwalk.Spec.Parameter}},
      servers: {:list, Moonwalk.Spec.Server},
      responses: Moonwalk.Spec.Responses,
      security: {:list, Moonwalk.Spec.SecurityRequirement}
    )
    |> collect()
  end

  def from_controller!(spec) do
    spec
    |> build(__MODULE__)
    |> rename_input(:operation_id, :operationId)
    |> rename_input(:request_body, :requestBody)
    |> take_required(:operationId)
    |> take_default(:tags, [])
    |> take_default(:parameters, [], &cast_params/1)
    |> take_default(:description, nil)
    |> take_required(:responses, &cast_responses/1)
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

  defp cast_params(parameters) when is_list(parameters) do
    parameters =
      if Keyword.keyword?(parameters) do
        Enum.map(parameters, fn {k, p} -> Parameter.from_controller!(p, k) end)
      else
        Enum.map(parameters, fn p -> Parameter.from_controller!(p, nil) end)
      end

    {:ok, parameters}
  end

  defp cast_params(other) do
    raise ArgumentError,
          "invalid parameters, expected a map, list or keyword list, got: #{inspect(other)}"
  end

  defp cast_responses(responses) when is_map(responses) do
    cast_responses(Map.to_list(responses))
  end

  defp cast_responses([]) do
    raise ArgumentError, "empty responses list or map"
  end

  defp cast_responses(responses) when is_list(responses) do
    normal =
      Map.new(responses, fn
        # TODO(doc) responses can be given as status codes. They will be validated.

        # We do not validate unknown integer status codes, this could be
        # blocking for users with special needs.
        {code, resp} when is_integer(code) ->
          {code, Response.from_controller!(resp)}

        {code, resp} ->
          {response_code!(code), Response.from_controller!(resp)}

        other ->
          raise ArgumentError,
                "invalid value in :responses, expected a map or keyword list, got item: #{inspect(other)}"
      end)

    {:ok, normal}
  end

  defp cast_responses(other) do
    raise ArgumentError, "operation macro expects a map or list of responses, got: #{inspect(other)}"
  end

  defp response_code!(status) do
    Plug.Conn.Status.code(status)
  rescue
    _ -> reraise ArgumentError, "invalid status given to :responses, got: #{inspect(status)}", __STACKTRACE__
  end
end
