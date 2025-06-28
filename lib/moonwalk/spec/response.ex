defmodule Moonwalk.Spec.Response do
  alias Moonwalk.Spec.MediaType
  alias Moonwalk.Spec.Reference
  import Moonwalk.Internal.ControllerBuilder
  require JSV
  use Moonwalk.Internal.SpecObject

  # Describes a single response from an API operation.
  JSV.defschema(%{
    title: "Response",
    type: :object,
    description: "Describes a single response from an API operation.",
    properties: %{
      description: %{type: :string, description: "A description of the response. Required."},
      headers: %{
        type: :object,
        additionalProperties: %{anyOf: [Moonwalk.Spec.Reference, Moonwalk.Spec.Header]},
        description: "A map of header names to their definitions."
      },
      content: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.MediaType,
        description: "A map of potential response payloads by media type."
      },
      links: %{
        type: :object,
        additionalProperties: %{anyOf: [Moonwalk.Spec.Reference, Moonwalk.Spec.Link]},
        description: "A map of operation links that can be followed from the response."
      }
    },
    required: [:description]
  })

  @impl true
  def normalize!(data, ctx) do
    data
    |> from(__MODULE__, ctx)
    |> normalize_default([:description])
    |> normalize_subs(
      headers: {:map, {:or_ref, Moonwalk.Spec.Header}},
      content: {:map, Moonwalk.Spec.MediaType},
      links: {:map, {:or_ref, Moonwalk.Spec.Link}}
    )
    |> collect()
  end

  # TODO(doc) document that atoms are used as schemas, but not maps anymore.
  # Maps are still used as schemas when given with a tuple.
  #
  # TODO(doc) a default description is provided
  def from_controller!(%Reference{} = ref) do
    ref
  end

  def from_controller!(schema) when is_atom(schema) when is_boolean(schema) do
    from_controller!({schema, []})
  end

  def from_controller!({schema, spec})
      when is_map(schema)
      when is_atom(schema)
      when is_boolean(schema) do
    spec =
      Keyword.put_new_lazy(spec, :description, fn ->
        case schema do
          %{description: d} when is_binary(d) -> d
          %{"description" => d} when is_binary(d) -> d
          _ -> "no description"
        end
      end)

    case Keyword.fetch(spec, :content) do
      :error ->
        spec = Keyword.put(spec, :content, %{"application/json" => %{schema: schema}})
        from_controller!(spec)

      _ ->
        raise ArgumentError,
              "cannot use a tuple definition for response with the :content option"
    end
  end

  def from_controller!(spec) when is_list(spec) when is_map(spec) do
    spec
    |> build(__MODULE__)
    |> take_required(:description)
    |> take_default(:content, nil, &cast_content/1)
    |> take_default(:headers, nil)
    |> take_default(:links, nil)
    |> into()
  end

  defp cast_content(content) when is_map(content) when is_list(content) do
    content
    |> Enum.to_list()
    |> Enum.reduce_while({:ok, %{}}, fn
      {mime_type, _media_spec}, _ when not is_binary(mime_type) ->
        {:halt, {:error, "media mime types must be strings, got: #{inspect(mime_type)}"}}

      {mime_type, media_spec}, {:ok, acc} ->
        case Plug.Conn.Utils.media_type(mime_type) do
          {:ok, _, _, _} ->
            media = MediaType.from_controller!(media_spec)
            {:cont, {:ok, Map.put(acc, mime_type, media)}}

          :error ->
            {:halt, {:error, "cannot parse media type #{inspect(mime_type)}"}}
        end
    end)
  end

  defp cast_content(content) do
    raise ArgumentError,
          "invalid :content given in response definition, expected map or keyword list,got: #{inspect(content)}"
  end
end
