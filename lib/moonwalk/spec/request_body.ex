defmodule Moonwalk.Spec.RequestBody do
  alias Moonwalk.Spec.MediaType
  import Moonwalk.Internal.ControllerBuilder
  require JSV
  use Moonwalk.Internal.SpecObject

  # Describes a single request body.
  JSV.defschema(%{
    title: "RequestBody",
    type: :object,
    description: "Describes a single request body.",
    properties: %{
      description: %{type: :string, description: "A brief description of the request body."},
      content: %{
        type: :object,
        additionalProperties: Moonwalk.Spec.MediaType,
        description: "A map containing the content of the request body by media type. Required."
      },
      required: %{
        type: :boolean,
        default: false,
        description: "Determines if the request body is required in the request."
      }
    },
    required: [:content]
  })

  def from_controller(spec) do
    {:ok, from_controller!(spec)}

    # The debang version is made to work with the cast system, there is no need to return {:error, _}
  end

  # TODO(doc) document that maps are always used as schemas
  def from_controller!(schema)
      when is_map(schema) or is_atom(schema)
      when is_boolean(schema) do
    from_controller!({schema, []})
  end

  # TODO(doc) document that required is set to true by default when passing a
  # schema
  def from_controller!({schema, spec}) do
    spec = Keyword.put_new(spec, :required, true)

    case Keyword.fetch(spec, :content) do
      :error ->
        spec = Keyword.put(spec, :content, %{"application/json" => %{schema: schema}})
        from_controller!(spec)

      _ ->
        raise ArgumentError,
              "cannot use a tuple definition for request body with the :content option"
    end
  end

  def from_controller!(spec) when is_list(spec) do
    spec
    |> build(__MODULE__)
    |> take_required(:content, &cast_content/1)
    |> take_default(:required, false)
    |> into()
  end

  defp cast_content(content) when is_map(content) when is_list(content) do
    content
    |> Enum.to_list()
    |> tap(fn
      [] -> raise ArgumentError, ":content cannot by empty"
      _ -> :ok
    end)
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
          "invalid :content given in request body definition, expected map or keyword list,got: #{inspect(content)}"
  end

  @impl true
  def normalize!(data, ctx) do
    data
    |> make(__MODULE__, ctx)
    |> normalize_default([:description, :required])
    |> normalize_subs(content: {:map, Moonwalk.Spec.MediaType})
    |> collect()
  end
end
