defmodule Moonwalk.Schema.BuildContext.Cached do
  @moduledoc false
  @enforce_keys [:id, :vocabularies, :meta, :raw, :anchors]
  defstruct @enforce_keys
  @opaque t :: %__MODULE__{}
end

defmodule Moonwalk.Schema.BuildContext do
  alias Moonwalk.Helpers
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
  defstruct [
    :ns,
    :root,
    staged_refs: [],
    opts: @default_opts,
    fetch_cache: %{},
    resolve_cache: %{},
    vocabularies: %{}
  ]

  defguardp is_not_blank(str) when is_binary(str) and str != ""

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
        {:error, reason} -> raise "#{inspect(unquote(tag))} error: #{inspect(reason)}"
        :error -> raise "#{inspect(unquote(tag))}, :error"
      end
    end
  end

  defmacro raise_err(body, {tag, _data}) when is_atom(tag) do
    quote do
      case unquote(body) do
        ok_tuple when elem(ok_tuple, 0) == :ok -> ok_tuple
        {:error, reason} -> raise "#{inspect(unquote(tag))} error: #{inspect(reason)}"
        :error -> raise "#{inspect(unquote(tag))}, :error"
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
    resolve_loop(ctx, [resolvable])
  end

  defp resolve_loop(ctx, [h | t]) do
    with {:ok, resolve_more, ctx} <- ensure_resolved(ctx, h) do
      resolve_loop(ctx, resolve_more ++ t)
    end
  end

  defp resolve_loop(ctx, []) do
    IO.puts("resolve finished")
    # {:current_stacktrace, ct} = Process.info(self(), :current_stacktrace)
    # Exception.format_stacktrace(ct) |> IO.puts()
    {:ok, ctx}
  end

  defp ensure_resolved(ctx, resolvable) do
    meta? =
      case resolvable do
        {:meta, _} -> true
        _ -> false
      end

    with :unresolved <- check_resolved(ctx, resolvable),
         {:ok, raw_schema, ctx} <- ensure_fetched(ctx, resolvable),
         {:ok, %{meta: cached_meta} = cached} <- raw_to_cached(raw_schema, resolvable),
         {:ok, sub_id_schemas} <- resolved_sub_ids(cached.raw, cached_meta, meta?) do
      resolve_more = [{:meta, cached_meta} | sub_id_schemas]

      {:ok, resolve_more, set_cached(ctx, cached, resolvable)}
    else
      :already_resolved -> {:ok, [], ctx}
      {:error, _} = err -> err
    end
  end

  defp resolved_sub_ids(raw_schema, meta, true = _meta?) do
    {:ok, []}
  end

  defp resolved_sub_ids(raw_schema, meta, false = _meta?) do
    sub_ids_to_resolvables(raw_schema, meta)
  end

  defp check_resolved(ctx, {:prefetched, id, _}) do
    check_resolved(ctx, id)
  end

  defp check_resolved(ctx, {:sub_id, id, _, meta}) do
    check_resolved(ctx, id)
  end

  defp check_resolved(ctx, id) when is_binary(id) or :root == id or elem(id, 0) == :meta do
    case ctx do
      %{resolve_cache: %{^id => _}} ->
        IO.puts("already resolved #{inspect(id)}")
        :already_resolved

      _ ->
        :unresolved
    end
  end

  defp check_resolved(ctx, %Ref{ns: ns}) do
    check_resolved(ctx, ns)
  end

  defp external_id({:prefetched, ext_id, _}) do
    ext_id
  end

  defp external_id({:meta, ext_id}) do
    ext_id
  end

  defp external_id({:sub_id, ext_id, _, _}) do
    ext_id
  end

  defp ensure_fetched(ctx, {:prefetched, ext_id, raw_schema}) do
    {:ok, raw_schema, ctx}
  end

  defp ensure_fetched(ctx, {:sub_id, ext_id, raw_schema, _}) do
    {:ok, raw_schema, ctx}
  end

  defp ensure_fetched(ctx, fetchable) do
    fetchable |> dbg()

    with :unfetched <- check_fetched(ctx, fetchable),
         {:ok, ext_id, raw_schema} <- fetch_raw_schema(ctx, fetchable) do
      %{fetch_cache: cache} = ctx
      {:ok, raw_schema, %__MODULE__{ctx | fetch_cache: Map.put(cache, ext_id, raw_schema)}}
    else
      {:already_fetched, raw_schema} -> {:ok, raw_schema, ctx}
      {:error, _} = err -> err
    end
  end

  defp check_fetched(ctx, {:meta, id}) do
    check_fetched(ctx, id)
  end

  defp check_fetched(_ctx, {:sub_id, _, raw_schema, _}) do
    {:already_fetched, raw_schema}
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

  # external_id is the url pointing to that schema. For instance if we find a
  # $ref: "http://example.com/schema.json" then the external_id is
  # "http://example.com/schema.json", but that schema could also have an $id, in
  # which case the $id will be declared as an alias.

  defp set_cached(ctx, cached, resolvable) do
    external_id = external_id(resolvable)
    true = nil != external_id

    cache_entries =
      case {external_id, cached.id} do
        {ext, nil} -> [{ext, cached}]
        # This never happens but it may?
        # {ext, id} -> [{ext , cached}, {id , {:alias_of, ext}}]
        {same, same} -> [{same, cached}]
      end

    cache_entries =
      case resolvable do
        {:meta, _} -> Enum.map(cache_entries, fn {k, v} -> {{:meta, k}, v} end)
        _ -> cache_entries
      end

    cache_entries = Map.new(cache_entries)

    %{resolve_cache: cache} = ctx
    cache = Map.merge(cache, cache_entries)
    %__MODULE__{ctx | resolve_cache: cache}
  end

  defp raw_to_cached(raw_schema, {:meta, _}) do
    ns = extract_id(raw_schema)
    vocabulary = Map.get(raw_schema, "$vocabulary")
    meta = Map.get(raw_schema, "$schema", nil)

    case load_vocabularies(vocabulary) do
      {:ok, vocabularies} ->
        {:ok, %Cached{id: ns, vocabularies: vocabularies, meta: meta, raw: raw_schema, anchors: []}}

      {:error, _} = err ->
        err
    end
  end

  defp raw_to_cached(raw_schema, {:prefetched, _ext_id, _}) do
    ns = extract_id(raw_schema)
    anchors = Map.new(find_anchors(raw_schema))
    meta = Map.get(raw_schema, "$schema", nil)

    {:ok, %Cached{id: ns, vocabularies: nil, meta: meta, raw: raw_schema, anchors: anchors}}
  end

  defp raw_to_cached(raw_schema, {:sub_id, _ext_id, _, meta}) do
    ns = extract_id(raw_schema)
    anchors = Map.new(find_anchors(raw_schema))

    {:ok, %Cached{id: ns, vocabularies: nil, meta: meta, raw: raw_schema, anchors: anchors}}
  end

  defp extract_id(raw_schema) do
    with {:ok, id} when is_binary(id) <- Map.fetch(raw_schema, "$id"),
         {:ok, ns} <- parse_id(id) do
      ns
    else
      _ -> nil
    end
  end

  defp parse_id(id) when is_binary(id) do
    case URI.parse(id) do
      %URI{scheme: scheme, host: host, fragment: nil} when is_binary(scheme) and is_binary(host) -> {:ok, id}
      _ -> {:error, {:invalid_id, id}}
    end
  end

  defp sub_ids_to_resolvables(raw_schema, meta) when is_map(raw_schema) do
    with {:ok, subs} <- collect_sub_id_schemas(raw_schema) do
      {:ok, Enum.map(subs, fn {id, schema} -> {:sub_id, id, schema, meta} end)}
    end
  end

  # Collect all sub schemas that define a $id property, except the top one.  At
  # each level, if a $id is encountered, it is passed as a context to nested
  # schemas, so if there are relative $id (like "some.json") it is converted in
  # a fully qualified id.
  defp collect_sub_id_schemas(raw_schema) do
    # The top id can be nil if all nested $id are fully qualified URIs
    {top_id, top_schema} = Map.pop(raw_schema, "$id", nil)

    case collect_sub_id_schemas(top_schema, top_id, []) do
      {:ok, acc} -> {:ok, :lists.flatten(acc)}
      {:error, _} = err -> err
    end
  end

  defp collect_sub_id_schemas(%{"$id" => sub_id} = sub_schema, parent_id, acc) do
    case merge_id(parent_id, sub_id) |> dbg() do
      {:ok, id} -> collect_sub_id_schemas_in_map(sub_schema, sub_id, [{id, sub_schema} | acc])
      {:error, _} = err -> err
    end
  end

  defp collect_sub_id_schemas(sub_schema, parent_id, acc) when is_map(sub_schema) do
    collect_sub_id_schemas_in_map(sub_schema, parent_id, acc)
  end

  defp collect_sub_id_schemas(list, parent_id, acc) when is_list(list) do
    Helpers.reduce_ok(list, acc, fn s, acc -> collect_sub_id_schemas(s, parent_id, acc) end)
  end

  defp collect_sub_id_schemas(scalar, _, acc) when is_binary(scalar) when is_atom(scalar) when is_number(scalar) do
    {:ok, acc}
  end

  defp collect_sub_id_schemas_in_map(sub_schema, parent_id, acc) when is_map(sub_schema) do
    Helpers.reduce_ok(sub_schema, acc, fn {_, s}, acc -> collect_sub_id_schemas(s, parent_id, acc) end)
  end

  defp merge_id(nil, uri) do
    with :ok <- check_full_uri(uri) do
      {:ok, uri}
    end
  end

  defp merge_id(parent, child) do
    merged = URI.merge(URI.parse(parent), URI.parse(child))

    with :ok <- check_full_uri(merged) do
      {:ok, URI.to_string(merged)}
    end
  rescue
    _ in ArgumentError -> {:error, {:unqualified_uri, child}}
  end

  defp check_full_uri(uri) do
    case URI.parse(uri) do
      %URI{scheme: "urn", host: nil, path: path} when is_not_blank(path) ->
        case String.split(path, ":", parts: 2) do
          [_, _] -> :ok
          _ -> {:error, {:unqualified_uri, uri}}
        end

      %URI{scheme: scheme, host: host} when is_not_blank(scheme) and is_not_blank(host) ->
        :ok

      _ ->
        {:error, {:unqualified_uri, uri}}
    end
  end

  defp find_anchors(raw_schema) do
    Map.new(collect_with_attr(raw_schema, "$anchor"))
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

  # The vocabularies are defined by the meta schema, so we do a double fetch
  defp fetch_vocabularies(ctx, ns) do
    with {:ok, cached} <- deref_cached(ctx, ns),
         {:ok, meta} <- deref_cached_meta(ctx, cached.meta) do
      {:ok, meta.vocabularies}
    else
      {:error, _} = err -> err
    end
  end

  defp fetch_raw(ctx, ns) do
    case deref_cached(ctx, ns) do
      {:ok, %{raw: raw}} -> {:ok, raw}
      {:error, _} = err -> err
    end
  end

  defp fetch_ref(ctx, ref) do
    %{ns: ns} = ref

    with {:ok, cached} <- deref_cached(ctx, ns) do
      case ref do
        %{kind: :docpath, arg: docpath} -> fetch_docpath(cached.raw, docpath) |> wrap_err({:invalid_ref, ref})
        %{kind: :top} -> {:ok, cached.raw}
        %{kind: :anchor, arg: anchor} -> Map.fetch(cached.anchors, anchor) |> wrap_err({:invalid_ref, ref})
      end
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

  defp do_fetch_docpath(raw_schema, [h | t]) do
    case Map.fetch(raw_schema, h) do
      {:ok, sub} -> do_fetch_docpath(sub, t)
      :error -> :error
    end
  end

  defp deref_cached(%{resolve_cache: cache}, ns) do
    # Map.fetch(cache, ns) |> wrap_err({:missing_cache, ns})
    Map.fetch(cache, ns) |> raise_err({:missing_cache, ns})
  end

  defp deref_cached_meta(ctx, ns) do
    deref_cached(ctx, {:meta, ns})
  end
end
