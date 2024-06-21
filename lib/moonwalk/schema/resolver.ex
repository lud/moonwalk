defmodule Moonwalk.Schema.Resolver do
  alias Moonwalk.Schema.Key
  alias Moonwalk.Schema.RNS
  alias Moonwalk.Helpers
  alias Moonwalk.Schema.Ref
  alias Moonwalk.Schema.Vocabulary

  defmodule Resolved do
    defstruct [:raw, :meta, :vocabularies]
  end

  @default_draft "http://json-schema.org/draft-07/schema"

  @draft_202012_vocabulary %{
    "https://json-schema.org/draft/2020-12/vocab/core" => Vocabulary.V202012.Core,
    "https://json-schema.org/draft/2020-12/vocab/validation" => Vocabulary.V202012.Validation,
    "https://json-schema.org/draft/2020-12/vocab/applicator" => Vocabulary.V202012.Applicator,
    "https://json-schema.org/draft/2020-12/vocab/content" => Vocabulary.V202012.Content,
    "https://json-schema.org/draft/2020-12/vocab/format-annotation" => Vocabulary.V202012.Format,
    "https://json-schema.org/draft/2020-12/vocab/format-assertion" => {Vocabulary.V202012.Format, assert: true},
    "https://json-schema.org/draft/2020-12/vocab/meta-data" => Vocabulary.V202012.MetaData,
    "https://json-schema.org/draft/2020-12/vocab/unevaluated" => Vocabulary.V202012.Unevaluated
  }
  @draft7_vocabulary %{
    "https://json-schema.org/draft-07/--fallback--vocab/core" => Vocabulary.VDraft7.Core,
    "https://json-schema.org/draft-07/--fallback--vocab/validation" => Vocabulary.VDraft7.Validation,
    "https://json-schema.org/draft-07/--fallback--vocab/applicator" => Vocabulary.VDraft7.Applicator
    # "https://json-schema.org/draft-07/--fallback--vocab/content" => Vocabulary.VDraft7.Content,
    # "https://json-schema.org/draft-07/--fallback--vocab/format-annotation" => Vocabulary.VDraft7.Format,
    # "https://json-schema.org/draft-07/--fallback--vocab/format-assertion" => {Vocabulary.VDraft7.Format, assert: true},
    # "https://json-schema.org/draft-07/--fallback--vocab/meta-data" => Vocabulary.VDraft7.MetaData,
    # "https://json-schema.org/draft-07/--fallback--vocab/unevaluated" => Vocabulary.VDraft7.Unevaluated
  }
  @draft7_vocabulary_keyword_fallback Map.new(@draft7_vocabulary, fn {k, _mod} -> {k, true} end)

  @vocabulary %{} |> Map.merge(@draft_202012_vocabulary) |> Map.merge(@draft7_vocabulary)

  @derive {Inspect, except: [:fetch_cache, :vocabularies, :ns, :dynamic_scope, :opts]}
  @enforce_keys [:root]
  defstruct [
    :ns,
    :root,
    staged_refs: [],
    opts: %{resolver: UnknownResolver},
    fetch_cache: %{},
    resolved: %{},
    vocabularies: %{},
    dynamic_scope: []
  ]

  @opaque t :: %__MODULE__{}

  # TODO build new_root as set_root(new(opts), raw_schema)
  def new_root(raw_schema, opts_map) when is_map(raw_schema) do
    # Bootstrap of the recursive resolving of schemas, metaschemas and
    # anchors/$ids. We just need to set the :root value in the context as the
    # $id (or `:root` atom if not set) of the top schema.

    root_ns = Map.get(raw_schema, "$id", :root)
    rsv = %__MODULE__{root: root_ns, opts: opts_map}

    with {:ok, rsv} <- resolve(rsv, {:prefetched, root_ns, raw_schema}),
         {:ok, vocabularies} <- fetch_vocabularies_for(rsv, root_ns) do
      {:ok, %__MODULE__{rsv | ns: root_ns, vocabularies: vocabularies}}
    else
      {:error, _} = err -> err
    end
  end

  def resolve(rsv, resolvable) do
    case check_resolved(rsv, resolvable) do
      :unresolved -> do_resolve(rsv, resolvable)
      :already_resolved -> {:ok, rsv}
    end
  end

  defp do_resolve(rsv, resolvable) do
    with {:ok, raw_schema, rsv} <- ensure_fetched(rsv, resolvable),
         {:ok, identified_schemas} <- scan_schema(raw_schema, external_id(resolvable)),
         {:ok, cache_entries} <- create_cache_entries(identified_schemas),
         {:ok, rsv} <- insert_cache_entries(rsv, cache_entries) do
      resolve_meta_loop(rsv, metas_of(cache_entries))
    else
      {:error, _} = err -> err
    end
  end

  defp metas_of(cache_entries) do
    Enum.flat_map(cache_entries, fn
      {_, {:alias_of, _}} -> []
      {_, v} -> [v.meta]
    end)
    |> Enum.uniq()
  end

  defp resolve_meta_loop(rsv, []) do
    {:ok, rsv}
  end

  # defp resolve_meta_loop(rsv, [nil | tail]) do
  #   resolve_meta_loop(rsv, tail)
  # end

  defp resolve_meta_loop(rsv, [meta | tail]) when is_binary(meta) do
    with :unresolved <- check_resolved(rsv, {:meta, meta}),
         {:ok, raw_schema, rsv} <- ensure_fetched(rsv, meta),
         {:ok, cache_entry} <- create_meta_entry(raw_schema),
         {:ok, rsv} <- insert_cache_entries(rsv, [{{:meta, meta}, cache_entry}]) do
      resolve_meta_loop(rsv, [cache_entry.meta | tail])
    else
      :already_resolved -> resolve_meta_loop(rsv, tail)
      {:error, _} = err -> err
    end
  end

  defp check_resolved(rsv, {:prefetched, id, _}) do
    check_resolved(rsv, id)
  end

  defp check_resolved(rsv, {:dynamic_anchor, ns, _}) do
    check_resolved(rsv, ns)
  end

  defp check_resolved(rsv, id) when is_binary(id) or :root == id do
    case rsv do
      %{resolved: %{^id => _}} -> :already_resolved
      _ -> :unresolved
    end
  end

  defp check_resolved(rsv, {:meta, id}) when is_binary(id) do
    case rsv do
      %{resolved: %{{:meta, ^id} => _}} -> :already_resolved
      _ -> :unresolved
    end
  end

  defp check_resolved(rsv, %Ref{ns: ns}) do
    check_resolved(rsv, ns)
  end

  # Extract all $ids and achors. We receive the top schema
  defp scan_schema(top_schema, external_id) when not is_nil(external_id) do
    id = Map.get(top_schema, "$id", nil)

    nss =
      case {id, external_id} do
        {nil, ext} -> [ext]
        {ext, ext} -> [ext]
        {local, ext} -> [local, ext]
      end

    # The schema will be findable by its $id or external id.
    id_aliases = nss

    # Anchor needs to be resolved from the $id or the external ID (an URL) if
    # set.
    anchor =
      case Map.fetch(top_schema, "$anchor") do
        {:ok, anchor} -> Enum.map(nss, &Key.for_anchor(&1, anchor))
        :error -> []
      end

    dynamic_anchor =
      case Map.fetch(top_schema, "$dynamicAnchor") do
        # a dynamic anchor is also adressable as a regular anchor for the given namespace
        {:ok, da} -> Enum.flat_map(nss, &[Key.for_dynamic_anchor(&1, da), Key.for_anchor(&1, da)])
        :error -> []
      end

    aliases = id_aliases ++ anchor ++ dynamic_anchor

    # If no metaschema is defined we will use the default draft as a fallback
    meta = Map.get(top_schema, "$schema", @default_draft)

    top_descriptor = %{raw: top_schema, meta: meta, aliases: aliases}

    # reverse the found schemas order so the top-ones appear first and
    # dynamicAnchor scope priority is respected.
    with {:ok, acc} <- scan_map_values(top_schema, id, nss, meta, [top_descriptor]) do
      {:ok, :lists.reverse(acc)}
    end
  end

  defp scan_subschema(raw_schema, parent_id, nss, meta, acc) when is_map(raw_schema) do
    # If the subschema defines an id, we will discard the current namespaces, as
    # the sibling or nested anchors will now only relate to this id

    id =
      with {:ok, rel_id} <- Map.fetch(raw_schema, "$id"),
           {:ok, full_id} <- merge_id(parent_id, rel_id) do
        full_id
      else
        _ -> nil
      end

    id_aliases =
      case id do
        nil -> []
        id -> [id]
      end

    nss =
      case id do
        nil -> nss
        id -> [id]
      end

    anchor =
      case Map.fetch(raw_schema, "$anchor") do
        {:ok, anchor} -> Enum.map(nss, &Key.for_anchor(&1, anchor))
        :error -> []
      end

    dynamic_anchor =
      case Map.fetch(raw_schema, "$dynamicAnchor") do
        # a dynamic anchor is also adressable as a regular anchor for the given namespace
        {:ok, da} -> Enum.flat_map(nss, &[Key.for_dynamic_anchor(&1, da), Key.for_anchor(&1, da)])
        :error -> []
      end

    # We do not check for the $meta is subschemas, we only add the parent_one to
    # the descriptor.
    #
    # If some aliases are found for the current schema we prepend it to the
    # accumulator. This means that the accumulator needs to be reversed before
    # creating the cache entries so the dynamicAnchors are resolved in scope
    # order.

    acc =
      case id_aliases ++ anchor ++ dynamic_anchor do
        [] ->
          acc

        aliases ->
          descriptor = %{raw: raw_schema, meta: meta, aliases: aliases}
          [descriptor | acc]
      end

    scan_map_values(raw_schema, id || parent_id, nss, meta, acc)
  end

  defp scan_subschema(scalar, _parent_id, _nss, _meta, acc)
       when is_binary(scalar)
       when is_atom(scalar)
       when is_number(scalar) do
    {:ok, acc}
  end

  defp scan_subschema(list, parent_id, nss, meta, acc) when is_list(list) do
    Helpers.reduce_ok(list, acc, fn item, acc -> scan_subschema(item, parent_id, nss, meta, acc) end)
  end

  defp scan_map_values(schema, parent_id, nss, meta, acc) do
    Helpers.reduce_ok(schema, acc, fn
      {"properties", props}, acc when is_map(props) ->
        scan_map_values(props, parent_id, nss, meta, acc)

      {"properties", props}, _ ->
        raise "TODO what are those properties?: #{inspect(props)}"

      {ignored, _}, _ when ignored in ["enum", "const"] ->
        {:ok, acc}

      {_k, v}, acc ->
        scan_subschema(v, parent_id, nss, meta, acc)
    end)
  end

  defp create_cache_entries(identified_schemas) do
    {:ok, Enum.flat_map(identified_schemas, &to_cache_entries/1)}
  end

  defp to_cache_entries(%{aliases: aliases, meta: meta, raw: raw}) do
    case aliases do
      [single] ->
        [{single, %Resolved{meta: meta, raw: raw}}]

      [first | aliases] ->
        [{first, %Resolved{meta: meta, raw: raw}} | Enum.map(aliases, &{&1, {:alias_of, first}})]
    end
  end

  defp insert_cache_entries(rsv, entries) do
    %{resolved: cache} = rsv

    cache_result =
      Helpers.reduce_ok(entries, cache, fn {k, v}, cache ->
        case cache do
          %{^k => _} -> {:error, {:duplicate_resolution, k}}
          _ -> {:ok, Map.put(cache, k, v)}
        end
      end)

    with {:ok, cache} <- cache_result do
      {:ok, %__MODULE__{rsv | resolved: cache}}
    end
  end

  defp create_meta_entry(raw_schema) do
    vocabulary = Map.get(raw_schema, "$vocabulary")
    # Do not default to latest meta on meta schema as we will not use it anyway
    # TODO we should not even recursively download metaschemas?
    meta = Map.get(raw_schema, "$schema", nil)
    id = Map.fetch!(raw_schema, "$id")

    case load_vocabularies(vocabulary, id) do
      {:ok, vocabularies} -> {:ok, %Resolved{vocabularies: vocabularies, meta: meta}}
      {:error, _} = err -> err
    end
  end

  defp external_id({:prefetched, ext_id, _}) do
    ext_id
  end

  defp external_id({:meta, ext_id}) do
    ext_id
  end

  defp external_id(%Ref{ns: ns}) do
    ns
  end

  defp ensure_fetched(rsv, {:prefetched, _, raw_schema}) do
    {:ok, raw_schema, rsv}
  end

  defp ensure_fetched(rsv, fetchable) do
    with :unfetched <- check_fetched(rsv, fetchable),
         {:ok, ext_id, raw_schema} <- fetch_raw_schema(rsv, fetchable) do
      %{fetch_cache: cache} = rsv
      {:ok, raw_schema, %__MODULE__{rsv | fetch_cache: Map.put(cache, ext_id, raw_schema)}}
    else
      {:already_fetched, raw_schema} -> {:ok, raw_schema, rsv}
      {:error, _} = err -> err
    end
  end

  defp check_fetched(rsv, %Ref{ns: ns}) do
    check_fetched(rsv, ns)
  end

  defp check_fetched(rsv, id) when is_binary(id) do
    case rsv do
      %{resolved: %{^id => fetched}} -> {:already_fetched, fetched}
      _ -> :unfetched
    end
  end

  def fetch_raw_schema(rsv, {:meta, url}) do
    fetch_raw_schema(rsv, url)
  end

  def fetch_raw_schema(rsv, url) when is_binary(url) do
    call_resolver(rsv.opts.resolver, url)
  end

  def fetch_raw_schema(rsv, %Ref{ns: ns}) do
    fetch_raw_schema(rsv, ns)
  end

  defp call_resolver(resolver, url) do
    case resolver.resolve(url) do
      {:ok, resolved} -> {:ok, url, resolved}
      {:error, _} = err -> err
    end
  end

  defp merge_id(nil, child) do
    RNS.derive(child, "")
  end

  defp merge_id(parent, child) do
    RNS.derive(parent, child)
  end

  # This function is called for all schemas, but only metaschemas should define
  # vocabulary, so nil is a valid vocabulary map. It will not be looked up for
  # normal schemas, and metaschemas without vocabulary should have a default
  # vocabulary in the library.
  defp load_vocabularies(nil, id)
       when id in [
              "http://json-schema.org/draft-07/schema",
              "http://json-schema.org/draft-07/schema#"
            ] do
    load_vocabularies(@draft7_vocabulary_keyword_fallback, id)
  end

  defp load_vocabularies(nil, id) do
    raise "Schema with $id #{inspect(id)} does not define vocabularies"
    {:ok, nil}
  end

  defp load_vocabularies(map, _) when is_map(map) do
    known =
      Enum.flat_map(map, fn {uri, required} ->
        case Map.fetch(@vocabulary, uri) do
          {:ok, module} -> [module]
          :error when required -> throw({:unknown_vocabulary, uri})
          :error -> []
        end
      end)

    {:ok, sort_vocabularies(known)}
  catch
    {:unknown_vocabulary, uri} -> {:error, {:unknown_vocabulary, uri}}
  end

  defp sort_vocabularies(modules) do
    Enum.sort_by(modules, fn
      {module, _} -> module.priority()
      module -> module.priority()
    end)
  end

  def as_root(rsv, fun) when is_function(fun, 2) do
    %{vocabularies: current_vocabs, ns: current_ns, root: root_ns} = rsv

    with {:ok, sub_vocabs} <- fetch_vocabularies_for(rsv, root_ns),
         {:ok, raw_schema} <- fetch_raw(rsv, root_ns),
         subrsv = %__MODULE__{rsv | ns: root_ns, vocabularies: sub_vocabs},
         {:ok, result, new_rsv} <- fun.(raw_schema, subrsv) do
      {:ok, result, %__MODULE__{new_rsv | ns: current_ns, vocabularies: current_vocabs}}
    else
      {:error, _} = err -> err
    end
  end

  def as_ref(rsv, %Ref{ns: ns} = ref, fun) when is_function(fun, 2) do
    %{vocabularies: current_vocabs, ns: current_ns} = rsv

    with {:ok, raw_subschema, meta} <- fetch_ref_raw_meta(rsv, ref),
         {:ok, sub_vocabs} <- fetch_vocabularies_of(rsv, meta),
         subrsv = %__MODULE__{rsv | ns: ns, vocabularies: sub_vocabs},
         {:ok, result, new_rsv} <- fun.(raw_subschema, subrsv) do
      {:ok, result, %__MODULE__{new_rsv | ns: current_ns, vocabularies: current_vocabs}}
    else
      {:error, _} = err -> err
    end
  end

  # If we build a subschema that has an $id we need to change the current
  # namespace so refs are relative to it.
  def as_sub(rsv, %{"$id" => sub_id} = raw_subschema, fun) when is_function(fun, 2) do
    %{ns: current_ns, dynamic_scope: current_scope} = rsv

    with {:ok, full_sub_id} <- merge_id(current_ns, sub_id),
         subrsv = %__MODULE__{rsv | ns: full_sub_id, dynamic_scope: [full_sub_id | current_scope]},
         {:ok, result, new_rsv} <- fun.(raw_subschema, subrsv) do
      {:ok, result, %__MODULE__{new_rsv | ns: current_ns, dynamic_scope: current_scope}}
    else
      {:error, _} = err -> err
    end
  end

  def as_sub(rsv, raw_subschema, fun) when is_function(fun, 2) when is_map(raw_subschema) do
    fun.(raw_subschema, rsv)
  end

  def fetch_vocabularies_for(rsv, %Resolved{meta: meta}) do
    fetch_vocabularies_of(rsv, meta)
  end

  def fetch_vocabularies_for(rsv, ns) do
    # The vocabularies are defined by the meta schema, so we do a double fetch
    with {:ok, %{meta: meta}} <- deref_resolved(rsv, ns) do
      fetch_vocabularies_of(rsv, meta)
    end
  end

  defp fetch_vocabularies_of(rsv, meta) do
    case deref_resolved(rsv, {:meta, meta}) do
      {:ok, %{vocabularies: vocabularies}} -> {:ok, vocabularies}
      {:error, _} = err -> err
    end
  end

  defp fetch_raw(rsv, ns) do
    case deref_resolved(rsv, ns) do
      {:ok, %{raw: raw}} -> {:ok, raw}
      {:error, _} = err -> err
    end
  end

  defp deref_resolved(%{resolved: cache} = rsv, key) do
    case Map.fetch(cache, key) do
      {:ok, {:alias_of, key}} -> deref_resolved(rsv, key)
      {:ok, cached} -> {:ok, cached}
      :error -> {:error, {:missed_cache, key}}
    end
  end

  def fetch_resolved(rsv, binary) when is_binary(binary) do
    do_fetch_resolved(rsv, binary)
  end

  def fetch_resolved(rsv, :root) do
    do_fetch_resolved(rsv, :root)
  end

  def fetch_resolved(rsv, {:pointer, ns, docpath}) do
    with {:ok, %{raw: raw, meta: meta}} <- deref_resolved(rsv, ns),
         {:ok, nested} <- fetch_docpath(raw, docpath) do
      {:ok, %Resolved{raw: nested, meta: meta}}
    end
  end

  def fetch_resolved(rsv, {:dynamic_anchor, _, _} = k) do
    do_fetch_resolved(rsv, k)
  end

  def fetch_resolved(rsv, {:anchor, _, _} = k) do
    do_fetch_resolved(rsv, k)
  end

  # def fetch_resolved(rsv, %Ref{} = ref) do
  #   fetch_ref(rsv, ref)
  # end

  # def fetch_resolved(rsv, {:dynamic_anchor, _, _} = k) do
  #   do_fetch_resolved(rsv, k)
  # end

  defp do_fetch_resolved(%{resolved: cache}, key) do
    case Map.fetch(cache, key) do
      {:ok, cached} -> {:ok, cached}
      :error -> {:error, {:missed_cache, key}}
    end
  end

  # When fetching a ref we deref aliases for anchors and docpaths as we need to
  # retrieve some potentially nested part of the JSON schema. For :top
  # references we can safely return the :alias_of tuple.

  defp fetch_ref_raw_meta(rsv, %Ref{dynamic?: false, kind: :top} = ref) do
    %{ns: ns} = ref

    with {:ok, %{raw: raw, meta: meta}} <- fetch_resolved(rsv, ns) do
      {:ok, raw, meta}
    end
  end

  # TODO $dynamicRef with docpath should be resolved too.
  defp fetch_ref_raw_meta(rsv, %Ref{dynamic?: _, kind: :docpath} = ref) do
    %{ns: ns, arg: docpath} = ref

    with {:ok, %{raw: raw, meta: meta}} <- deref_resolved(rsv, ns),
         {:ok, raw} <- fetch_docpath(raw, docpath) do
      {:ok, raw, meta}
    end
  end

  defp fetch_ref_raw_meta(rsv, %Ref{dynamic?: false, kind: :anchor} = ref) do
    %{ns: ns, arg: anchor} = ref

    with {:ok, %{raw: raw, meta: meta}} <- deref_resolved(rsv, {:anchor, ns, anchor}) do
      {:ok, raw, meta}
    end
  end

  # Dynamic anchor
  defp fetch_ref_raw_meta(rsv, %Ref{dynamic?: true, kind: :anchor} = ref) do
    raise "is this used?"
    %{ns: ns, arg: anchor} = ref

    # Try to resolve as a regular ref if no dynamic anchor is found
    cached_result =
      with {:error, {:missed_cache, first_error}} <- deref_resolved(rsv, {:dynamic_anchor, anchor}),
           {:error, {:missed_cache, _}} <- deref_resolved(rsv, {:anchor, ns, anchor}) do
        {:error, {:missed_cache, first_error}}
      end

    with {:ok, %{raw: raw, meta: meta}} <- cached_result do
      {:ok, raw, meta}
    end
  end

  defp fetch_docpath(raw_schema, docpath) do
    case do_fetch_docpath(raw_schema, docpath) do
      {:ok, v} -> {:ok, v}
      :error -> {:error, {:invalid_docpath, docpath, raw_schema}}
    end
  end

  defp do_fetch_docpath(raw_schema, []) do
    {:ok, raw_schema}
  end

  defp do_fetch_docpath(list, [h | t]) when is_list(list) and is_integer(h) do
    with {:ok, item} <- Enum.fetch(list, h) do
      do_fetch_docpath(item, t)
    end
  end

  defp do_fetch_docpath(raw_schema, [h | t]) when is_map(raw_schema) and is_binary(h) do
    case Map.fetch(raw_schema, h) do
      {:ok, sub} -> do_fetch_docpath(sub, t)
      :error -> :error
    end
  end
end
