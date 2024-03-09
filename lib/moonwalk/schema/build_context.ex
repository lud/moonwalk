defmodule Moonwalk.Schema.BuildContext do
  alias Moonwalk.Schema.Ref
  alias Moonwalk.Schema.Vocabulary

  @default_opts %{resolver: UnknownResolver}
  @default_opts_list Map.to_list(@default_opts)

  @vocabulary %{
    "https://json-schema.org/draft/2020-12/vocab/core" => Vocabulary.V202012.Core,
    "https://json-schema.org/draft/2020-12/vocab/validation" => Vocabulary.V202012.Validation,
    "https://json-schema.org/draft/2020-12/vocab/applicator" => Vocabulary.V202012.Applicator,
    "https://json-schema.org/draft/2020-12/vocab/content" => Vocabulary.V202012.Content,
    "https://json-schema.org/draft/2020-12/vocab/format-annotation" => Vocabulary.V202012.Format,
    "https://json-schema.org/draft/2020-12/vocab/meta-data" => Vocabulary.V202012.MetaData,
    "https://json-schema.org/draft/2020-12/vocab/unevaluated" => Vocabulary.V202012.Unevaluated
  }

  @enforce_keys [:ns]
  defstruct [:ns, staged_refs: [], opts: @default_opts, resolved: %{}, vocabularies: %{}]

  @opaque t :: %__MODULE__{}

  def default_opts_list do
    @default_opts_list
  end

  def new_root(raw_schema, opts_map) when is_map(raw_schema) do
    ns =
      with {:ok, id} when is_binary(id) <- Map.fetch(raw_schema, "$id"),
           {:ok, ns} <- parse_ns(id) do
        ns
      else
        _ -> :root
      end

    %__MODULE__{opts: opts_map, resolved: %{ns => raw_schema}, ns: ns}
  end

  defp parse_ns(ns) do
    case URI.parse(ns) do
      %URI{scheme: scheme, host: host, fragment: nil} when is_binary(scheme) and is_binary(host) -> {:ok, ns}
      %URI{scheme: "file"} -> :file
      _ -> :unknown
    end
  end

  def load_vocabulary(ctx, meta_uri) do
    with {:ok, raw_meta, ctx} <- ensure_resolved(ctx, meta_uri),
         {:ok, vocabulary_map} <- fetch_vocabulary_map(raw_meta),
         {:ok, vocabularies} <- load_vocabularies(vocabulary_map) do
      {:ok, %__MODULE__{ctx | vocabularies: vocabularies}}
    end
  end

  defp fetch_vocabulary_map(raw_meta) do
    case raw_meta do
      %{"$vocabulary" => vocabulary} -> {:ok, vocabulary}
      _ -> {:error, :no_vocabulary}
    end
  end

  defp load_vocabularies(map) when is_map(map) do
    known =
      Enum.flat_map(map, fn {uri, required} ->
        case Map.fetch(@vocabulary, uri) do
          {:ok, module} -> [module]
          :error when required -> throw({:unknown_vocabulary, uri})
          :error -> []
        end
      end)

    {:ok, known}
  catch
    {:unknown_vocabulary, uri} -> {:error, {:unknown_vocabulary, uri}}
  end

  def ensure_resolved(ctx, uri) when is_binary(uri) do
    url = to_doc_url(uri)

    case ctx do
      %{resolved: %{^url => resolved}} ->
        {:ok, resolved, ctx}

      %{resolved: missing, opts: %{resolver: resolver}} ->
        with {:ok, resolved} <- call_resolver(resolver, url) do
          {:ok, resolved, %__MODULE__{ctx | resolved: Map.put(missing, url, resolved)}}
        end
    end
  end

  def ensure_resolved(ctx, %Ref{ns: ns}) do
    ensure_resolved(ctx, ns)
  end

  defp to_doc_url(%URI{} = uri) do
    URI.to_string(%URI{uri | fragment: nil})
  end

  defp to_doc_url(uri) when is_binary(uri) do
    uri |> URI.parse() |> to_doc_url()
  end

  defp call_resolver(resolver, url) do
    resolver.resolve(url)
  end

  def stage_ref(%{staged_refs: staged} = ctx, ref) do
    %__MODULE__{ctx | staged_refs: put_unseen(staged, ref)}
  end

  defp put_unseen([], ref) do
    [ref]
  end

  def take_staged(%{staged_refs: []} = ctx) do
    {:empty, ctx}
  end

  def take_staged(%{staged_refs: [h | t]} = ctx) do
    {h, %__MODULE__{ctx | staged_refs: t}}
  end
end
