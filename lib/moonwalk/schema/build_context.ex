defmodule Moonwalk.Schema.BuildContext do
  alias Moonwalk.Schema.RNS
  alias Moonwalk.Helpers
  alias Moonwalk.Schema.Ref
  alias Moonwalk.Schema.Vocabulary

  @default_opts %{resolver: UnknownResolver}
  @default_opts_list Map.to_list(@default_opts)

  @latest_draft "https://json-schema.org/draft/2020-12/schema"
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
  defstruct [
    :ns,
    :root,
    staged_refs: [],
    opts: @default_opts,
    fetch_cache: %{},
    resolve_cache: %{},
    vocabularies: %{}
  ]

  defmacro wrap_err(body, tag) when is_atom(tag) do
    quote do
      case unquote(body) do
        ok_tuple when elem(ok_tuple, 0) == :ok -> ok_tuple
        {:error, reason} -> {:error, {unquote(tag), reason}}
        :error -> {:error, unquote(tag)}
      end
    end
  end

  defmacro wrap_err(body, {tag, data}) when is_atom(tag) do
    quote do
      case unquote(body) do
        ok_tuple when elem(ok_tuple, 0) == :ok -> ok_tuple
        {:error, reason} -> {:error, {unquote(tag), unquote(data), reason}}
        :error -> {:error, {unquote(tag), unquote(data)}}
      end
    end
  end

  defmacro raise_err(body, tag) when is_atom(tag) do
    quote do
      case unquote(body) do
        ok_tuple when elem(ok_tuple, 0) == :ok -> ok_tuple
        {:error, reason} -> raise "#{inspect(unquote(tag))}, error: #{inspect(reason)}"
        :error -> raise "#{inspect(unquote(tag))}, :error"
      end
    end
  end

  defmacro raise_err(body, {tag, data}) when is_atom(tag) do
    quote do
      case unquote(body) do
        ok_tuple when elem(ok_tuple, 0) == :ok -> ok_tuple
        {:error, reason} -> raise "#{inspect(unquote(tag))} (#{inspect(unquote(data))}), error: #{inspect(reason)}"
        :error -> raise "#{inspect(unquote(tag))} (#{inspect(unquote(data))}), :error"
      end
    end
  end

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
    resolve(ctx, {:prefetched, root_ns, raw_schema})
  end

  def resolve(ctx, resolvable) do
    case check_resolved(ctx, resolvable) do
      :unresolved -> do_resolve(ctx, resolvable)
      :already_resolved -> {:ok, ctx}
    end
  end

  defp do_resolve(ctx, resolvable) do
    with {:ok, raw_schema, ctx} <- ensure_fetched(ctx, resolvable),
         {:ok, identified_schemas} <- scan_schema(raw_schema, external_id(resolvable)),
         {:ok, cache_entries} <- create_cache_entries(identified_schemas),
         {:ok, ctx} <- insert_cache_entries(ctx, cache_entries) do
      resolve_meta_loop(ctx, metas_of(cache_entries))
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

  defp resolve_meta_loop(ctx, []) do
    {:ok, ctx}
  end

  defp resolve_meta_loop(ctx, [nil | tail]) do
    resolve_meta_loop(ctx, tail)
  end

  defp resolve_meta_loop(ctx, [meta | tail]) when is_binary(meta) do
    with :unresolved <- check_resolved(ctx, {:meta, meta}),
         {:ok, raw_schema, ctx} <- ensure_fetched(ctx, meta),
         {:ok, cache_entry} <- create_meta_entry(raw_schema),
         {:ok, ctx} <- insert_cache_entries(ctx, [{{:meta, meta}, cache_entry}]) do
      resolve_meta_loop(ctx, [cache_entry.meta | tail])
    else
      :already_resolved -> {:ok, ctx}
      {:error, _} = err -> err
    end
  end

  defp check_resolved(ctx, {:prefetched, id, _}) do
    check_resolved(ctx, id)
  end

  defp check_resolved(ctx, id) when is_binary(id) or :root == id do
    case ctx do
      %{resolve_cache: %{^id => _}} -> :already_resolved
      _ -> :unresolved
    end
  end

  defp check_resolved(ctx, {:meta, id}) when is_binary(id) do
    case ctx do
      %{resolve_cache: %{{:meta, ^id} => _}} -> :already_resolved
      _ -> :unresolved
    end
  end

  defp check_resolved(ctx, %Ref{ns: ns}) do
    check_resolved(ctx, ns)
  end

  # Extract all $ids and achors. We receive the top schema
  defp scan_schema(top_schema, external_id) when not is_nil(external_id) do
    id = Map.get(top_schema, "$id", nil)

    nss =
      case {id, external_id} do
        {nil, ext} -> [ext]
        {ext, ext} -> [ext]
        {id, ext} -> [id, ext]
      end

    # The schema will be findable by its $id or external id.
    id_aliases = nss

    # Anchor needs to be resolved from the $id or the external ID (an URL) if
    # set.
    anchor =
      case Map.fetch(top_schema, "$anchor") do
        {:ok, anchor} -> Enum.map(nss, &{:anchor, &1, anchor})
        :error -> []
      end

    dynamic_anchor =
      case Map.fetch(top_schema, "$dynamicAnchor") do
        {:ok, dynamic_anchor} -> [{:dynamic_anchor, dynamic_anchor}]
        :error -> []
      end

    aliases = id_aliases ++ anchor ++ dynamic_anchor

    # If no metaschema is defined we will use the latest draft
    meta = Map.get(top_schema, "$schema", @latest_draft)

    top_descriptor = %{raw: top_schema, meta: meta, aliases: aliases}

    scan_map_values(top_schema, id, nss, meta, [top_descriptor])
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
        {:ok, anchor} -> Enum.map(nss, &{:anchor, &1, anchor})
        :error -> []
      end

    dynamic_anchor =
      case Map.fetch(raw_schema, "$dynamicAnchor") do
        {:ok, dynamic_anchor} -> [{:dynamic_anchor, dynamic_anchor}]
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
          top_descriptor = %{raw: raw_schema, meta: meta, aliases: aliases}
          [top_descriptor | acc]
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

      {_k, v}, acc ->
        scan_subschema(v, parent_id, nss, meta, acc)
    end)
  end

  defp create_cache_entries(identified_schemas) do
    {:ok, Enum.flat_map(identified_schemas, &to_cache_entries/1)}
  end

  defp to_cache_entries(%{aliases: aliases, meta: meta, raw: raw}) do
    case aliases do
      [single] -> [{single, %{meta: meta, raw: raw}}]
      [first | aliases] -> [{first, %{meta: meta, raw: raw}} | Enum.map(aliases, &{&1, {:alias_of, first}})]
    end
  end

  defp insert_cache_entries(ctx, entries) do
    %{resolve_cache: cache} = ctx

    cache_result =
      Helpers.reduce_ok(entries, cache, fn
        {{:dynamic_anchor, _} = k, v}, cache ->
          {:ok, Map.put_new(cache, k, v)}

        {k, v}, cache ->
          case cache do
            %{^k => _} -> {:error, {:duplicate_resolution, k}}
            _ -> {:ok, Map.put(cache, k, v)}
          end
      end)

    with {:ok, cache} <- cache_result do
      {:ok, %__MODULE__{ctx | resolve_cache: cache}}
    end
  end

  defp create_meta_entry(raw_schema) do
    vocabulary = Map.get(raw_schema, "$vocabulary")
    # Do not default to latest meta on meta schema as we will not use it anyway
    # TODO we should not even recursively download metaschemas?
    meta = Map.get(raw_schema, "$schema", nil)

    case load_vocabularies(vocabulary) do
      {:ok, vocabularies} -> {:ok, %{vocabularies: vocabularies, meta: meta}}
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

  defp ensure_fetched(ctx, {:prefetched, _, raw_schema}) do
    {:ok, raw_schema, ctx}
  end

  defp ensure_fetched(ctx, fetchable) do
    with :unfetched <- check_fetched(ctx, fetchable),
         {:ok, ext_id, raw_schema} <- fetch_raw_schema(ctx, fetchable) do
      %{fetch_cache: cache} = ctx
      {:ok, raw_schema, %__MODULE__{ctx | fetch_cache: Map.put(cache, ext_id, raw_schema)}}
    else
      {:already_fetched, raw_schema} -> {:ok, raw_schema, ctx}
      {:error, _} = err -> err
    end
  end

  defp check_fetched(ctx, %Ref{ns: ns}) do
    check_fetched(ctx, ns)
  end

  defp check_fetched(ctx, id) when is_binary(id) do
    case ctx do
      %{resolve_cache: %{^id => _}} -> :already_fetched
      _ -> :unfetched
    end
  end

  def fetch_raw_schema(ctx, {:meta, url}) do
    fetch_raw_schema(ctx, url)
  end

  def fetch_raw_schema(ctx, url) when is_binary(url) do
    call_resolver(ctx.opts.resolver, url)
  end

  def fetch_raw_schema(ctx, %Ref{ns: ns}) do
    fetch_raw_schema(ctx, ns)
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
    %__MODULE__{ctx | staged_refs: append_unique(staged, ref)}
  end

  defp append_unique([ref | t], ref) do
    append_unique(t, ref)
  end

  defp append_unique([h | t], ref) do
    [h | append_unique(t, ref)]
  end

  defp append_unique([], ref) do
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

    with {:ok, sub_vocabs} <- fetch_vocabularies_for(ctx, root_ns),
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

    with {:ok, raw_subschema, meta} <- fetch_ref(ctx, ref),
         {:ok, sub_vocabs} <- fetch_vocabularies_of(ctx, meta),
         subctx = %__MODULE__{ctx | ns: ns, vocabularies: sub_vocabs},
         {:ok, result, new_ctx} <- fun.(raw_subschema, subctx) do
      {:ok, result, %__MODULE__{new_ctx | ns: current_ns, vocabularies: current_vocabs}}
    else
      {:error, _} = err -> err
    end
  end

  # If we build a subschema that has an $id we need to change the current
  # namespace so refs are relative to it.
  def as_sub(ctx, %{"$id" => sub_id} = raw_subschema, fun) when is_function(fun, 2) do
    %{ns: current_ns} = ctx

    with {:ok, full_sub_id} <- merge_id(current_ns, sub_id),
         subctx = %__MODULE__{ctx | ns: full_sub_id},
         {:ok, result, new_ctx} <- fun.(raw_subschema, subctx) do
      {:ok, result, %__MODULE__{new_ctx | ns: current_ns}}
    else
      {:error, _} = err -> err
    end
  end

  def as_sub(ctx, raw_subschema, fun) when is_function(fun, 2) when is_map(raw_subschema) do
    fun.(raw_subschema, ctx)
  end

  defp fetch_vocabularies_for(ctx, ns) do
    # The vocabularies are defined by the meta schema, so we do a double fetch
    with {:ok, %{meta: meta}} <- deref_cached(ctx, ns) do
      fetch_vocabularies_of(ctx, meta)
    end
  end

  defp fetch_vocabularies_of(ctx, meta) do
    case deref_cached(ctx, {:meta, meta}) do
      {:ok, %{vocabularies: vocabularies}} -> {:ok, vocabularies}
      {:error, _} = err -> err
    end
  end

  defp fetch_raw(ctx, ns) do
    case deref_cached(ctx, ns) do
      {:ok, %{raw: raw}} -> {:ok, raw}
      {:error, _} = err -> err
    end
  end

  defp fetch_ref(ctx, %Ref{dynamic?: false, kind: :anchor} = ref) do
    %{ns: ns, arg: anchor} = ref

    with {:ok, %{raw: raw, meta: meta}} <- deref_cached(ctx, {:anchor, ns, anchor}) do
      {:ok, raw, meta}
    end
  end

  defp fetch_ref(ctx, %Ref{dynamic?: false, kind: :docpath} = ref) do
    %{ns: ns, arg: docpath} = ref

    with {:ok, %{raw: raw, meta: meta}} <- deref_cached(ctx, ns),
         {:ok, raw} <- fetch_docpath(raw, docpath) do
      {:ok, raw, meta}
    end
  end

  defp fetch_ref(ctx, %Ref{dynamic?: false, kind: :top} = ref) do
    %{ns: ns} = ref

    with {:ok, %{raw: raw, meta: meta}} <- deref_cached(ctx, ns) do
      {:ok, raw, meta}
    end
  end

  defp fetch_ref(ctx, %Ref{dynamic?: true, kind: :anchor} = ref) do
    %{arg: anchor} = ref

    with {:ok, %{raw: raw, meta: meta}} <- deref_cached(ctx, {:dynamic_anchor, anchor}) do
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

  defp deref_cached(%{resolve_cache: cache} = ctx, key) do
    case Map.fetch(cache, key) do
      {:ok, {:alias_of, alias_of}} -> deref_cached(ctx, alias_of)
      {:ok, cached} -> {:ok, cached}
      :error -> {:error, {:missed_cache, key}}
    end
  end
end
