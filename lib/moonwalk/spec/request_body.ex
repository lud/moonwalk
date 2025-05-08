defmodule Moonwalk.Spec.RequestBody do
  alias Moonwalk.Spec.MediaType
  import Moonwalk.Spec

  @enforce_keys [:content]
  defstruct required: false, content: nil, description: nil

  def build(spec, opts) do
    {:ok, build!(spec, opts)}
  end

  def build!(schema, opts) when is_map(schema) or is_atom(schema) when is_boolean(schema) do
    build!({schema, []}, opts)
  end

  def build!({schema, spec}, opts) when is_list(opts) do
    case Keyword.fetch(opts, :content) do
      :error ->
        spec = Keyword.put(spec, :content, %{"application/json" => %{schema: schema}})
        build!(spec, opts)

      _ ->
        raise ArgumentError,
              "cannot use a tuple definition for request body with the :content option"
    end
  end

  def build!(spec, opts) when is_list(spec) do
    spec
    |> make(:request_body)
    |> take_required(:content, &cast_content(&1, opts))
    |> take_default(:required, false)
    |> into(__MODULE__)
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
              media = MediaType.build!(media_spec, opts)
              Map.put(acc, mime_type, media)

            :error ->
              raise ArgumentError,
                    "cannot parse media type #{inspect(mime_type)}"
          end
      end)

    {:ok, map}
  end
end
