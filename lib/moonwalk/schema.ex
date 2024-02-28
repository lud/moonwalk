defmodule Moonwalk.Schema do
  defstruct [:meta, :layers, :raw, :refs, :defs, :resolve_context]

  defmodule BooleanSchema do
    defstruct [:value]
  end

  def denormalize(schema) do
    {:ok, denormalize!(schema)}
  end

  def denormalize!(%{"$schema" => vsn} = json_schema) do
    denormalize!(json_schema, %{vsn: vsn}, :root)
  end

  def denormalize!(json_schema) do
    denormalize!(json_schema, %{}, :root)
  end

  def denormalize!(bool, _meta, _rctx) when is_boolean(bool) do
    %BooleanSchema{value: bool}
  end

  def denormalize!(json_schema, meta, resolve_context \\ :sub) do
    schema =
      %__MODULE__{
        meta: meta,
        layers: [],
        raw: json_schema,
        refs: [],
        defs: %{},
        resolve_context: resolve_context
      }

    # :resolve_context tells whether we are in the top schema, a sub schema of
    # the same json schema document, or an external or external+sub imported via
    # $ref.
    %{layers: layers} = schema = Enum.reduce(json_schema, schema, &denorm/2)

    {layers, refs} = pull_refs(layers, [])
    layers = merge_layers(layers)

    # Collect refs and store it on the schema. So they can be stolen by a parent
    # schema if there is one, otherwise our resolve_context is :root and we will
    # extract the defs from the refs and denormalize them as well.
    schema = %{schema | layers: layers, refs: refs}

    case resolve_context do
      :root -> resolve_refs(schema)
      :sub -> schema
    end
  end

  defp merge_layers(layers) do
    layers
    |> Enum.filter(fn
      [] -> false
      _ -> true
    end)
    |> Enum.map(fn
      [{k, _} | _] = layer
      when k in [:properties, :pattern_properties, :additional_properties] ->
        merge_properties_layer(layer)

      [{k, _} | _] = layer
      when k in [:items, :prefix_items] ->
        merge_items_layer(layer)

      other ->
        other
    end)
  end

  defp merge_properties_layer(layer) do
    properties = Keyword.get(layer, :properties, nil)
    pattern_properties = Keyword.get(layer, :pattern_properties, nil)
    additional_properties = Keyword.get(layer, :additional_properties, nil)
    [{:all_properties, {properties, pattern_properties, additional_properties}}]
  end

  defp merge_items_layer(layer) do
    items = Keyword.get(layer, :items, nil)
    prefix_items = Keyword.get(layer, :prefix_items, nil)

    [{:all_items, {items, prefix_items}}]
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

  defp pull_refs(map, acc) when is_map(map) do
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

  defp resolve_refs(schema) do
    resolve_refs(schema.refs, schema, %{})
  end

  defp resolve_refs([h | t], schema, seen) when is_map_key(seen, h) do
    resolve_refs(t, schema, seen)
  end

  defp resolve_refs([ref | tail], schema, seen) do
    %{raw: json_schema, meta: meta, defs: defs} = schema
    raw_sub = resolve_ref(json_schema, parse_ref(ref))
    subschema = denormalize!(raw_sub, meta)
    {subschema, tail} = pull_refs(subschema, tail)

    schema = %__MODULE__{schema | defs: Map.put(defs, ref, subschema)}
    seen = Map.put(seen, ref, true)

    resolve_refs(tail, schema, seen)
  end

  defp resolve_refs([], schema, seen) do
    # once resolved, refs aren't used anymore, but for the sake of clarity we
    # want people to see all what was pulled.
    %{schema | refs: Map.keys(seen)} |> dbg()
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

    {new_list, acc} = fun.(Map.new(mapped), acc)
    {new_list, acc} |> dbg()
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

  defp denorm({"$schema", vsn}, %{meta: meta} = s) do
    %__MODULE__{s | meta: Map.put(meta, :vsn, vsn)}
  end

  defp denorm({"type", type}, s) do
    type = valid_type!(type)
    put_checker(s, layer_of(:type), {:type, type})
  end

  defp denorm({"const", value}, s) do
    put_checker(s, layer_of(:const), {:const, value})
  end

  defp denorm({"items", items_schema}, s) do
    subschema = denormalize!(items_schema, s.meta)
    put_checker(s, layer_of(:items), {:items, subschema})
  end

  defp denorm({"prefixItems", [_ | _] = schemas}, s) do
    subschemas = Enum.map(schemas, &denormalize!(&1, s.meta))
    put_checker(s, layer_of(:prefix_items), {:prefix_items, subschemas})
  end

  defp denorm({"allOf", schemas}, s) do
    subschemas = Enum.map(schemas, &denormalize!(&1, s.meta))
    put_checker(s, layer_of(:all_of), {:all_of, subschemas})
  end

  defp denorm({"oneOf", schemas}, s) do
    subschemas = Enum.map(schemas, &denormalize!(&1, s.meta))
    put_checker(s, layer_of(:one_of), {:one_of, subschemas})
  end

  defp denorm({"anyOf", schemas}, s) do
    subschemas = Enum.map(schemas, &denormalize!(&1, s.meta))
    put_checker(s, layer_of(:any_of), {:any_of, subschemas})
  end

  defp denorm({"$defs", defs_map}, s) when is_map(defs_map) do
    s
    # subschemas_map = Map.new(defs_map, fn {k, raw} -> {k, denormalize!(raw, s.meta)} end)
    # %{s | defs: subschemas_map}
  end

  defp denorm({"additionalProperties", schema}, s) do
    subschema = denormalize!(schema, s.meta)
    put_checker(s, layer_of(:additional_properties), {:additional_properties, subschema})
  end

  defp denorm({"patternProperties", props}, s) when is_map(props) do
    subschemas =
      Map.new(props, fn {k, v} when is_binary(k) ->
        {{k, Regex.compile!(k)}, denormalize!(v, s.meta)}
      end)

    put_checker(s, layer_of(:pattern_properties), {:pattern_properties, subschemas})
  end

  defp denorm({"properties", props}, s) when is_map(props) do
    subschemas = Map.new(props, fn {k, v} -> {k, denormalize!(v, s.meta)} end)
    put_checker(s, layer_of(:properties), {:properties, subschemas})
  end

  defp denorm({"required", keys}, s) when is_list(keys) do
    put_checker(s, layer_of(:required), {:required, keys})
  end

  defp denorm({"$ref", ref}, s) when is_binary(ref) do
    s = collect_ref(s, ref)
    put_checker(s, layer_of(:"$ref"), {:"$ref", ref})
  end

  defp denorm({:boolean_schema, _} = ck, s) do
    put_checker(s, layer_of(:boolean_schema), ck)
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
    defp denorm({unquote(external), value}, s) do
      put_checker(s, layer_of(unquote(internal)), {unquote(internal), value})
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
    defp denorm({unquote(external), value}, s) when is_integer(value) do
      put_checker(s, layer_of(unquote(internal)), {unquote(internal), value})
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
    defp denorm({unquote(external), value}, s) when is_number(value) do
      put_checker(s, layer_of(unquote(internal)), {unquote(internal), value})
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
      :boolean_schema,
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

  defp put_checker(%__MODULE__{layers: layers} = s, layer, checker) do
    layers = put_in_layer(layers, layer, checker)
    %__MODULE__{s | layers: layers}
  end

  defp collect_ref(%__MODULE__{refs: refs} = s, ref) do
    %__MODULE__{s | refs: [ref | refs]}
  end

  defp put_in_layer([h | t], 0, checker) do
    [[checker | h] | t]
  end

  defp put_in_layer([h | t], n, checker) do
    [h | put_in_layer(t, n - 1, checker)]
  end

  defp put_in_layer([], 0, checker) do
    [[checker]]
  end

  defp put_in_layer([], n, checker) do
    [[] | put_in_layer([], n - 1, checker)]
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
