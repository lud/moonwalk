defmodule Moonwalk.Schema.Context do
  @moduledoc false
  defstruct [
    :uri,
    :vsn
  ]
end

defmodule Moonwalk.Schema do
  alias Moonwalk.Schema.Context

  defstruct [
    # Non-validating informations
    :meta,
    # Lists of validators
    :layers,
    # Raw JSON schema
    :raw,
    # Refs found during denormalization of the schema, not used once refs are
    # resolved and put into defs.
    :refs,
    # Schemas that are referenced by $ref in the schema.
    :defs
  ]

  defmodule BooleanSchema do
    defstruct [:value]
  end

  # raise """
  # TODO denormalize with remote refs

  # 1. do not rely on :root/:sub to know if we need to resolve.
  #    Just call resolve_refs in denormalize/1
  # 2. store {:root, ref} or {"http://....", ref} in layers. Split the remote url
  #    and fragment to ref is always local to the left part of the tuple.
  # 3. in the defs (and so in the context), organize the schemas with the same
  #    keys: {:root, ref}.
  # 4. when denormalizing a remote schema, pass the opts but do not pass meta, so
  #    a new context is createt BUT still steal the refs/defs!
  # 5. use a remote resolver to target priv/schemas/draft-2020-12.schema.json
  # """

  def denormalize(schema, opts \\ []) do
    {:ok, denormalize!(schema, opts)}
    # TODO rescue
  end

  def denormalize!(json_schema, opts \\ [])

  def denormalize!(json_schema, opts) when is_map(json_schema) do
    # pulling the vsn in the top schema, we cannot support having a different
    # version nested somewhere.
    vsn = Map.get(json_schema, "$schema", nil)
    ctx = %Context{uri: :root, vsn: vsn}
    schema = child!(json_schema, ctx)
    schema = resolve_refs(schema, ctx)
    schema
  end

  def denormalize!(bool, _opts) when is_boolean(bool) do
    %BooleanSchema{value: bool}
  end

  def child!(bool, _ctx) when is_boolean(bool) do
    %BooleanSchema{value: bool}
  end

  def child!(json_schema, ctx) when is_map(json_schema) do
    schema =
      %__MODULE__{
        meta: %{vsn: ctx.vsn},
        layers: [],
        raw: json_schema,
        refs: [],
        defs: %{}
      }

    validators =
      json_schema
      |> Stream.map(fn kv -> cast_pair(kv, ctx) end)
      |> Enum.reject(&(&1 == :ignore))

    {validators, refs} = pull_refs(validators, [])

    layers = assemble_layers(validators)

    # Collect refs and store it on the schema. So they can be stolen by a parent
    # schema if there is one, otherwise our resolve_context is :root and we will
    # extract the defs from the refs and denormalize them as well.
    %{schema | layers: layers, refs: refs}
  end

  defp cast_pair({"type", type}, ctx) do
    type = valid_type!(type)
    {:type, type}
  end

  defp cast_pair({"const", value}, ctx) do
    {:const, value}
  end

  defp cast_pair({"items", items_schema}, ctx) do
    subschema = child!(items_schema, ctx)
    {:items, subschema}
  end

  defp cast_pair({"prefixItems", [_ | _] = schemas}, ctx) do
    subschemas = Enum.map(schemas, &child!(&1, ctx))
    {:prefix_items, subschemas}
  end

  defp cast_pair({"allOf", schemas}, ctx) do
    subschemas = Enum.map(schemas, &child!(&1, ctx))
    {:all_of, subschemas}
  end

  defp cast_pair({"oneOf", schemas}, ctx) do
    subschemas = Enum.map(schemas, &child!(&1, ctx))
    {:one_of, subschemas}
  end

  defp cast_pair({"anyOf", schemas}, ctx) do
    subschemas = Enum.map(schemas, &child!(&1, ctx))
    {:any_of, subschemas}
  end

  defp cast_pair({"additionalProperties", schema}, ctx) do
    subschema = child!(schema, ctx)
    {:additional_properties, subschema}
  end

  defp cast_pair({"patternProperties", props}, ctx) when is_map(props) do
    subschemas =
      Map.new(props, fn {k, v} when is_binary(k) ->
        {{k, Regex.compile!(k)}, child!(v, ctx)}
      end)

    {:pattern_properties, subschemas}
  end

  defp cast_pair({"properties", props}, ctx) when is_map(props) do
    subschemas = Map.new(props, fn {k, v} -> {k, child!(v, ctx)} end)
    {:properties, subschemas}
  end

  defp cast_pair({"required", keys}, ctx) when is_list(keys) do
    {:required, keys}
  end

  defp cast_pair({"$ref", ref}, ctx) when is_binary(ref) do
    {:"$ref", ref}
  end

  [
    # Passthrough schema properties – we do not use them but we must accept them
    # as they are part of the defined properties of a schema.
    content_encoding: "contentEncoding",
    content_media_type: "contentMediaType",
    content_schema: "contentSchema",
    required: "required",
    enum: "enum"
  ]
  |> Enum.each(fn {internal, external} ->
    defp cast_pair({unquote(external), value}, _ctx) do
      {unquote(internal), value}
    end
  end)

  [
    # Passthrough schema properties that only accept integers
    multiple_of: "multipleOf",
    min_items: "minItems",
    max_items: "maxItems",
    max_length: "maxLength",
    min_length: "minLength"
  ]
  |> Enum.each(fn {internal, external} ->
    defp cast_pair({unquote(external), value}, _ctx) when is_integer(value) do
      {unquote(internal), value}
    end
  end)

  [
    # Passthrough schema properties that only accept numbers
    minimum: "minimum",
    maximum: "maximum",
    exclusive_minimum: "exclusiveMinimum",
    exclusive_maximum: "exclusiveMaximum"
  ]
  |> Enum.each(fn {internal, external} ->
    defp cast_pair({unquote(external), value}, _ctx) when is_number(value) do
      {unquote(internal), value}
    end
  end)

  [
    # Ignore these properties
    "$schema",
    "$defs"
  ]
  |> Enum.each(fn external ->
    defp cast_pair({unquote(external), _}, _ctx) do
      :ignore
    end
  end)

  # TODO @optimize make layer_of/1 a macro so we compile to literal integers
  # when deciding the layer
  layers = [
    [
      :"$ref",
      :"$defs",
      :all_of,
      :any_of,
      :one_of,
      :const,
      :enum,
      :content_encoding,
      :content_media_type,
      :content_schema,
      :maximum,
      :minimum,
      :exclusive_maximum,
      :exclusive_minimum,
      :min_items,
      :max_items,
      :multiple_of,
      :type,
      :max_length,
      :min_length,
      :required
    ],
    [:items, :prefix_items],
    [
      :additional_properties,
      :properties,
      :pattern_properties
    ]
  ]

  for {checkers, n} <- Enum.with_index(layers), c <- checkers do
    def layer_of(unquote(c)) do
      unquote(n)
    end
  end

  defp assemble_layers(validators) do
    Enum.reduce(validators, [], fn {k, v}, layers -> put_in_layer(layers, layer_of(k), {k, v}) end)
  end

  # Layers is a list of lists, so when putting in layer at index, we "cons" the
  # item in the list that is at index N of the top list, or we merge it if it is
  # a compound layer (properties+patternProperties+additionalProperties or
  # items+prefixItems)

  defp put_in_layer([layer | layers], 0, checker) do
    [merge_layer(layer, checker) | layers]
  end

  defp put_in_layer([], 0, checker) do
    # inner list does not exist yet
    [merge_layer([], checker)]
  end

  defp put_in_layer([h | t], n, checker) do
    [h | put_in_layer(t, n - 1, checker)]
  end

  defp put_in_layer([], n, checker) do
    [[] | put_in_layer([], n - 1, checker)]
  end

  defp merge_layer([], {k, _} = tuple)
       when k in [:properties, :pattern_properties, :additional_properties] do
    # merged layer does not exist yet
    merge_layer([{:all_properties, {nil, nil, nil}}], tuple)
  end

  defp merge_layer([], {k, _} = tuple) when k in [:items, :prefix_items] do
    # merged layer does not exist yet
    merge_layer([{:all_items, {nil, nil}}], tuple)
  end

  defp merge_layer([{:all_properties, {ps, pts, _}}], {:additional_properties, schema}) do
    [{:all_properties, {ps, pts, schema}}]
  end

  defp merge_layer([{:all_properties, {p, _, ap}}], {:pattern_properties, schema}) do
    [{:all_properties, {p, schema, ap}}]
  end

  defp merge_layer([{:all_properties, {_, pts, ap}}], {:properties, schema}) do
    [{:all_properties, {schema, pts, ap}}]
  end

  # same with items and prefix items
  defp merge_layer([{:all_items, {_, pi}}], {:items, schema}) do
    [{:all_items, {schema, pi}}]
  end

  defp merge_layer([{:all_items, {i, _}}], {:prefix_items, schema}) do
    [{:all_items, {i, schema}}]
  end

  # for all other validators we just cons' them in the layer
  defp merge_layer(list, tuple) do
    [tuple | list]
  end

  defp pull_refs(term, acc)

  defp pull_refs(list, acc) when is_list(list) do
    Enum.map_reduce(list, acc, fn item, acc -> pull_refs(item, acc) end)
  end

  defp pull_refs({:"$ref", ref}, acc) when is_binary(ref) do
    {{:"$ref", ref}, [ref | acc]}
  end

  defp pull_refs({:"$ref", other}, acc) do
    raise "todo ref not a string: #{inspect(other)}"
  end

  defp pull_refs({k, v}, acc) when is_atom(k) do
    {v, acc} = pull_refs(v, acc)
    {{k, v}, acc}
  end

  defp pull_refs(scalar, acc)
       when is_binary(scalar)
       when is_atom(scalar)
       when is_number(scalar) do
    {scalar, acc}
  end

  defp pull_refs(%__MODULE__{} = s, acc) do
    {s, refs} = steal_refs(s)
    {s, refs ++ acc}
  end

  defp pull_refs(%BooleanSchema{} = s, acc) do
    {s, acc}
  end

  defp pull_refs(map, acc) when is_map(map) and not is_struct(map) do
    {as_list, acc} =
      Enum.map_reduce(map, acc, fn {k, v}, acc ->
        {v2, acc} = pull_refs(v, acc)
        {{k, v2}, acc}
      end)

    {Map.new(as_list), acc}
  end

  # STEAL the refs from sub schema
  defp steal_refs(%__MODULE__{refs: refs} = schema) do
    {%{schema | refs: []}, refs}
  end

  defp resolve_refs(schema, ctx) do
    resolve_refs(schema.refs, schema, %{}, ctx)
  end

  defp resolve_refs([h | t], schema, seen, ctx) when is_map_key(seen, h) do
    h |> dbg()
    resolve_refs(t, schema, seen, ctx)
  end

  defp resolve_refs([ref | tail], schema, seen, ctx) do
    %{raw: json_schema, meta: meta, defs: defs} = schema
    raw_sub = resolve_ref(json_schema, parse_ref(ref))
    subschema = child!(raw_sub, meta)
    {subschema, tail} = pull_refs(subschema, tail)

    schema = %__MODULE__{schema | defs: Map.put(defs, ref, subschema)}
    seen = Map.put(seen, ref, true)

    resolve_refs(tail, schema, seen, ctx)
  end

  defp resolve_refs([], schema, _seen, _ctx) do
    schema
  end

  defp parse_ref(ref) do
    _uri = URI.parse(ref)
  end

  defp resolve_ref(raw_schema, %{host: nil, path: nil, fragment: "/" <> path}) do
    segments = String.split(path, "/")

    case get_in(raw_schema, segments) do
      nil -> raise "Could not resolve ref: #{inspect(path)}"
      schema -> schema
    end
  end

  defp traverse_layers(list, acc, fun) when is_list(list) do
    {mapped, acc} =
      Enum.reduce(list, {[], acc}, fn el, {mapped, acc} ->
        {new_el, acc} = traverse_layers(el, acc, fun)
        {[new_el | mapped], acc}
      end)

    {new_list, acc} = fun.(:lists.reverse(mapped), acc)
    {new_list, acc}
  end

  defp traverse_layers(%__MODULE__{layers: layers} = s, acc, fun) do
    traverse_layers(layers, acc, fun)
  end

  defp traverse_layers(%BooleanSchema{} = s, acc, fun) do
    fun.(s, acc)
  end

  defp traverse_layers(map, acc, fun) when is_map(map) do
    {mapped, acc} =
      Enum.reduce(map, {[], acc}, fn {k, v}, {mapped, acc} ->
        {new_v, acc} = traverse_layers(v, acc, fun)
        {[{k, new_v} | mapped], acc}
      end)

    fun.(Map.new(mapped), acc)
  end

  defp traverse_layers(tuple, acc, fun) when is_tuple(tuple) do
    {list, acc} =
      tuple
      |> Tuple.to_list()
      |> traverse_layers(acc, fun)

    fun.(List.to_tuple(list), acc)
  end

  defp traverse_layers(el, acc, _fun) when is_binary(el) when is_atom(el) when is_number(el) do
    {el, acc}
  end

  defp valid_type!(list) when is_list(list) do
    Enum.map(list, &valid_type!/1)
  end

  defp valid_type!("array") do
    :array
  end

  defp valid_type!("object") do
    :object
  end

  defp valid_type!("null") do
    :null
  end

  defp valid_type!("boolean") do
    :boolean
  end

  defp valid_type!("string") do
    :string
  end

  defp valid_type!("integer") do
    :integer
  end

  defp valid_type!("number") do
    :number
  end

  defdelegate validate(data, schema), to: Moonwalk.Schema.Validator
end
