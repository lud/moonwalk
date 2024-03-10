defmodule Moonwalk.Schema.BuildContext.Cached do
  @moduledoc false
  @enforce_keys [:id, :vocabularies, :meta, :raw, :anchors]
  defstruct @enforce_keys
  @opaque t :: %__MODULE__{}
end

defmodule Moonwalk.Schema.BuildContext do
  alias Moonwalk.Schema.BuildContext.Cached
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

  @enforce_keys [:root]
  defstruct [:ns, :root, staged_refs: [], opts: @default_opts, fetch_cache: %{}, vocabularies: %{}]

  @opaque t :: %__MODULE__{}

  def default_opts_list do
    @default_opts_list
  end

  def for_root(raw_schema, opts_map) when is_map(raw_schema) do
    # Bootstrap of the recursive resolving of schemas, metaschemas and
    # anchors/$ids. We just need to set the :root value in the context as the
    # $id (or `:root` atom if not set) of the top schema.

    root_ns = Map.get(raw_schema, "$id", :root)
    ctx = %__MODULE__{root: root_ns, opts: opts_map}
    ensure_resolved(ctx, {:prefetched, root_ns, raw_schema})
  end

  def ensure_resolved(ctx, uri_or_ref_or_prefetch) do
    resolve_loop(ctx, [uri_or_ref_or_prefetch])
  end

  defp resolve_loop(ctx, [h | t]) do
    with {:ok, ext_id, resolved} <- resolve_one(ctx, h),
         {:ok, cached} <- raw_to_cached(resolved) do
      ctx = set_cached(ctx, ext_id, cached)
      resolve_loop(ctx, [cached.meta | sub_ids_to_prefetched(cached.raw)] ++ t)
    else
      :already_resolved -> resolve_loop(ctx, t)
      {:error, _} = err -> {:error, err}
    end
  end

  defp resolve_loop(ctx, []) do
    {:ok, ctx}
  end

  def resolve_one(ctx, url) when is_binary(url) and is_map_key(ctx.fetch_cache, url) do
    :already_resolved
  end

  def resolve_one(ctx, url) when is_binary(url) do
    call_resolver(ctx.opts.resolver, url)
  end

  def resolve_one(ctx, {:prefetched, id, _}) when is_binary(id) and is_map_key(ctx.fetch_cache, id) do
    :already_resolved
  end

  def resolve_one(_ctx, {:prefetched, id, raw_schema}) do
    {:ok, id, raw_schema}
  end

  def resolve_one(_ctx, %Ref{ns: :root}) do
    :already_resolved
  end

  def resolve_one(ctx, %Ref{ns: ns}) do
    resolve_one(ctx, ns)
  end

  defp call_resolver(resolver, url) do
    case resolver.resolve(url) do
      {:ok, resolved} -> {:ok, url, resolved}
      {:error, _} = err -> err
    end
  end

  # external_id is the url pointing to that schema. For instance if we find a
  # $ref: "http://example.com/schema.json" then the external_id is
  # "http://example.com/schema.json", but that schema could also have an $id, in
  # which case the $id will be declared as an alias.
  defp set_cached(ctx, external_id, cached) do
    cache_entries =
      case {external_id, cached.id} do
        {nil, nil} -> raise "cannot register schema without neither an $id or an URL pointing to it"
        {nil, id} -> %{id => cached}
        {ext, nil} -> %{ext => cached}
        # This never happens but it may?
        # {ext, id} -> %{ext => cached, id => {:alias_of, ext}}
        {same, same} -> %{same => cached}
      end

    %{fetch_cache: cache} = ctx
    cache = Map.merge(cache, cache_entries)
    %__MODULE__{ctx | fetch_cache: cache}
  end

  defp raw_to_cached(raw_schema) do
    ns =
      with {:ok, id} when is_binary(id) <- Map.fetch(raw_schema, "$id"),
           {:ok, ns} <- parse_ns(id) do
        ns
      else
        _ -> nil
      end

    vocabulary = Map.get(raw_schema, "$vocabulary", nil)

    anchors = Map.new(find_anchors(raw_schema))

    case load_vocabularies(vocabulary) do
      {:ok, vocabularies} ->
        meta = Map.get(raw_schema, "$schema", nil)
        {:ok, %Cached{id: ns, vocabularies: vocabularies, meta: meta, raw: raw_schema, anchors: anchors}}

      {:error, _} = err ->
        err
    end
  end

  defp parse_ns(ns) when is_binary(ns) do
    case URI.parse(ns) do
      %URI{scheme: scheme, host: host, fragment: nil} when is_binary(scheme) and is_binary(host) ->
        {:ok, ns}

      _ ->
        {:error, {:invalid_ns, ns}}
    end
  end

  defp find_anchors(raw_schema) do
    Map.new(collect_with_attr(raw_schema, "$anchor"))
  end

  defp sub_ids_to_prefetched(raw_schema) when is_map(raw_schema) do
    subs = collect_with_attr(Map.delete(raw_schema, "$id"), "$id")
    Enum.map(subs, fn {id, schema} -> {:prefetched, id, schema} end)
  end

  # Returns a list of pairs with all schemas and subschemas that define the
  # given key.  For instance if key is $anchor, then it returns a list of pairs
  # where the left items are the anchors and the right items the corresponding
  # schemas, possibly including the top schema, and with some subschemas nested
  # in other subschemas
  defp collect_with_attr(raw_schema, key) do
    collect_with_attr(raw_schema, key, [])
  end

  defp collect_with_attr(map, key, acc) when is_map_key(map, key) do
    acc = [{Map.fetch!(map, key), map} | acc]
    collect_with_attr_map(map, key, acc)
  end

  defp collect_with_attr(map, key, acc) when is_map(map) do
    collect_with_attr_map(map, key, acc)
  end

  defp collect_with_attr(list, key, acc) when is_list(list) do
    Enum.reduce(list, acc, fn v, acc -> collect_with_attr(v, key, acc) end)
  end

  defp collect_with_attr(_scalar, _key, acc) do
    acc
  end

  defp collect_with_attr_map(map, key, acc) do
    Enum.reduce(map, acc, fn {_k, v}, acc -> collect_with_attr(v, key, acc) end)
  end

  # This function is called for all schemas, but only metaschemas should define
  # vocabulary, so nil is a valid vocabulary map. It will not be looked up for
  # normal schemas, and metaschemas without vocabulary should have a default
  # vocabulary in the library.
  defp load_vocabularies(nil) do
    {:ok, nil}
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

  def stage_ref(%{staged_refs: staged} = ctx, ref) do
    %__MODULE__{ctx | staged_refs: put_unseen(staged, ref)}
  end

  defp put_unseen([ref | t], ref) do
    [ref | t]
  end

  defp put_unseen([h | t], ref) do
    [h | put_unseen(t, ref)]
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

  def as_root(ctx, fun) when is_function(fun, 2) do
    %{vocabularies: current_vocabs, ns: current_ns, root: root_ns} = ctx

    with {:ok, sub_vocabs} <- fetch_vocabularies(ctx, root_ns),
         {:ok, raw_schema} <- fetch_raw(ctx, root_ns),
         subctx = %__MODULE__{ctx | ns: root_ns, vocabularies: sub_vocabs},
         {:ok, result, new_ctx} <- fun.(raw_schema, subctx) do
      {:ok, result, %__MODULE__{new_ctx | ns: current_ns, vocabularies: current_vocabs}}
    else
      {:error, _} = err -> err
    end
  end

  def as_ref(ctx, %Ref{ns: ns} = ref, fun) when is_function(fun, 2) do
    %{vocabularies: current_vocabs, ns: current_ns} = ctx

    with {:ok, sub_vocabs} <- fetch_vocabularies(ctx, ns),
         {:ok, raw_subschema} <- fetch_ref(ctx, ref),
         subctx = %__MODULE__{ctx | ns: ns, vocabularies: sub_vocabs},
         {:ok, result, new_ctx} <- fun.(raw_subschema, subctx) do
      {:ok, result, %__MODULE__{new_ctx | ns: current_ns, vocabularies: current_vocabs}}
    else
      {:error, _} = err -> err
    end
  end

  # The vocabularies are defined by the meta schema, so we do a double fetch
  defp fetch_vocabularies(ctx, ns) do
    with {:ok, cached} <- fetch_cached(ctx, ns),
         {:ok, meta} <- fetch_cached(ctx, cached.meta) do
      {:ok, meta.vocabularies}
    else
      {:error, _} = err -> err
    end
  end

  defp fetch_raw(ctx, ns) do
    case fetch_cached(ctx, ns) do
      {:ok, %{raw: raw}} -> {:ok, raw}
      {:error, _} = err -> err
    end
  end

  defp fetch_ref(ctx, ref) do
    %{ns: ns} = ref

    with {:ok, cached} <- fetch_cached(ctx, ns) do
      case ref do
        %{kind: :docpath, docpath: docpath} -> fetch_docpath(cached.raw, docpath)
      end
    end
  end

  defp fetch_docpath(raw_schema, docpath) do
    case do_fetch_docpath(raw_schema, docpath) do
      {:ok, v} -> {:ok, v}
      {:error, :invalid_docpath} -> {:error, {:invalid_docpath, docpath, raw_schema}}
    end
  end

  defp do_fetch_docpath(raw_schema, []) do
    {:ok, raw_schema}
  end

  defp do_fetch_docpath(raw_schema, [h | t]) do
    case Map.fetch(raw_schema, h) do
      {:ok, sub} -> do_fetch_docpath(sub, t)
      :error -> {:error, :invalid_docpath}
    end
  end

  defp fetch_cached(%{fetch_cache: cache}, ns) do
    Map.fetch(cache, ns)
  end
end
