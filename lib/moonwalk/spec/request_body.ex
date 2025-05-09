defmodule Moonwalk.Spec.RequestBody do
  alias Moonwalk.Spec.MediaType
  require JSV
  use Moonwalk.Spec

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
        description: "Determines if the request body is required in the request."
      }
    },
    required: [:content]
  })

  def from_controller(spec, opts \\ [])

  def from_controller(spec, opts) do
    {:ok, from_controller!(spec, opts)}
  end

  def from_controller!(schema, opts)
      when is_map(schema) or is_atom(schema)
      when is_boolean(schema) do
    from_controller!({schema, []}, opts)
  end

  def from_controller!({schema, spec}, opts) when is_list(opts) do
    case Keyword.fetch(opts, :content) do
      :error ->
        spec = Keyword.put(spec, :content, %{"application/json" => %{schema: schema}})
        from_controller!(spec, opts)

      _ ->
        raise ArgumentError,
              "cannot use a tuple definition for request body with the :content option"
    end
  end

  def from_controller!(spec, opts) when is_list(spec) do
    spec
    |> make(__MODULE__)
    |> take_required(:content, &cast_content(&1, opts))
    |> take_default(:required, false)
    |> into()
  end

  defp cast_content(content, opts) when is_map(content) when is_list(content) do
    map =
      content
      |> Enum.to_list()
      |> tap(fn
        [] -> raise ArgumentError, ":content cannot by empty"
        _ -> :ok
      end)
      |> Enum.reduce(%{}, fn
        {mime_type, _media_spec}, _ when not is_binary(mime_type) ->
          {:halt, {:error, "media mime types must be strings, got: #{inspect(mime_type)}"}}

        {mime_type, media_spec}, acc ->
          case Plug.Conn.Utils.media_type(mime_type) do
            {:ok, _, _, _} ->
              media = MediaType.from_controller!(media_spec, opts)
              Map.put(acc, mime_type, media)

            :error ->
              raise ArgumentError,
                    "cannot parse media type #{inspect(mime_type)}"
          end
      end)

    {:ok, map}
  end
end
