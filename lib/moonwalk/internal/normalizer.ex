defmodule Moonwalk.Internal.Normalizer do
  alias Moonwalk.Errors.NormalizeError
  alias Moonwalk.Spec.NormalizationContext
  alias Moonwalk.Spec.OpenAPI
  alias Moonwalk.Spec.Reference

  @moduledoc false

  @enforce_keys [:data, :target, :out, :ctx]
  defstruct @enforce_keys
  @type t :: %__MODULE__{}

  @callback normalize!(term, NormalizationContext.t()) :: {struct, NormalizationContext.t()}

  IO.warn("remove fallback impl of normalize in quoted")

  defmacro __using__(_) do
    # placeholder for future functionality
    # TODO replace `use` by `import` if not used
    quote do
      import unquote(__MODULE__)
      @behaviour unquote(__MODULE__)
      snake_object_name =
        __MODULE__
        |> Module.split()
        |> List.last()
        |> Macro.underscore()

      object_name =
        snake_object_name
        |> String.replace(~r{(^|_).}, fn
          "_" <> char -> " " <> String.upcase(char)
          char -> " " <> String.upcase(char)
        end)

      object_fragment =
        snake_object_name
        |> String.replace("_", "-")
        |> Kernel.<>("-object")

      obect_link = "https://spec.openapis.org/oas/v3.1.1.html##{object_fragment}"

      @moduledoc "Representation of the [#{object_name} Object](#{obect_link}) in OpenAPI Specification."

      @impl true
      def normalize!(_, _) do
        raise "this is only to suppress warnings"
      end

      defoverridable normalize!: 2
    end
  end

  def normalize!(data) do
    ctx = %NormalizationContext{seen_schema_mods: %{}, schemas: %{}, path: []}
    {normal, ctx} = normalize!(data, OpenAPI, ctx)
    put_in(normal, [Access.key("components", %{}), Access.key("schemas", %{})], ctx.schemas)
  end

  def normalize!(data, target, ctx) do
    target.normalize!(data, ctx)
  end

  def make(%target{} = data, target, ctx) do
    make(JSV.Helpers.MapExt.from_struct_no_nils(data), target, ctx)
  end

  def make(data, target, ctx) when is_map(data) do
    %__MODULE__{data: data, target: target, ctx: ctx, out: []}
  end

  def make(other, target, ctx) do
    raise NormalizeError,
      ctx: ctx,
      reason: "invalid value for Open API model #{inspect(target)}, expected a map or struct, got: #{inspect(other)}"
  end

  def normalize_subs(bld, keymap) when is_list(keymap) do
    %__MODULE__{data: data, target: target, ctx: ctx, out: outlist} = bld

    {data, outlist, ctx} =
      Enum.reduce(keymap, {data, outlist, ctx}, fn {key, caster}, {data, outlist, ctx} = acc ->
        case pop_normal(data, key) do
          {:ok, bin_key, {value, data}} ->
            {cast_value, ctx} = downpath(ctx, bin_key, &apply_caster(value, caster, &1))
            {data, [{bin_key, cast_value} | outlist], ctx}

          :error ->
            acc
        end
      end)

    %__MODULE__{data: data, target: target, ctx: ctx, out: outlist}
  end

  # accepting a function to handle additional properties
  def normalize_subs(bld, handler) when is_function(handler, 3) do
    %__MODULE__{data: data, ctx: ctx, out: outlist} = bld

    {outlist, ctx} =
      Enum.reduce(data, {outlist, ctx}, fn {key, value}, {outlist, ctx} ->
        bin_key = ensure_binary_key(key)
        {value, ctx} = downpath(ctx, bin_key, &handler.(bin_key, value, &1))
        {[{bin_key, value} | outlist], ctx}
      end)

    %{bld | data: %{}, ctx: ctx, out: outlist}
  end

  def normalize_default(bld, :all) do
    %__MODULE__{data: data, out: outlist} = bld

    outlist =
      Enum.reduce(data, outlist, fn {key, value}, outlist ->
        [{ensure_binary_key(key), to_json_decoded(value)} | outlist]
      end)

    %{bld | data: %{}, out: outlist}
  end

  def normalize_default(bld, keys) when is_list(keys) do
    normalize_subs(bld, Enum.map(keys, &{&1, :default}))
  end

  def normalize_schema(bld, key) when is_atom(key) do
    %__MODULE__{data: data, ctx: ctx, out: outlist} = bld

    case pop_normal(data, key) do
      {:ok, bin_key, {schema, data}} ->
        {replacement_schema, ctx} = do_normalize_schema(schema, ctx)
        %{bld | data: data, ctx: ctx, out: [{bin_key, replacement_schema} | outlist]}

      :error ->
        bld
    end
  end

  def skip(bld, key) when is_atom(key) do
    %__MODULE__{data: data} = bld

    case pop_normal(data, key) do
      {:ok, _bin_key, {_value, data}} -> %{bld | data: data}
      :error -> bld
    end
  end

  if Mix.env() == :prod do
    def collect(%__MODULE__{data: data, target: target, ctx: ctx, out: outlist}) do
      {Map.new(outlist), ctx}
    end
  else
    def collect(%__MODULE__{data: data, target: target, ctx: ctx, out: outlist}) do
      case map_size(data) do
        0 ->
          :ok

        _ ->
          raise NormalizeError,
            ctx: ctx,
            reason: "some keys were not normalized from #{inspect(target)}: #{inspect(Map.keys(data))}"
      end

      {Map.new(outlist), ctx}
    end
  end

  defp downpath(ctx, key, fun) do
    {retval, ctx} = fun.(push_path(ctx, key))
    {retval, pop_path(ctx)}
  end

  def current_path(ctx) do
    :lists.reverse(ctx.path)
  end

  def push_path(ctx, key) when is_binary(key) when is_integer(key) and key >= 0 do
    %{ctx | path: [key | ctx.path]}
  end

  def pop_path(ctx) do
    [_ | path] = ctx.path
    %{ctx | path: path}
  end

  # pops a key regardless of atom/binary encoding:
  # * If the key is in the map, we pop it
  # * Otherwise if the key is an atom, we try to pop its binary form
  # * If nothing works it's an error
  #
  # The function also returns the binary key
  defp pop_normal(map, key) when is_map_key(map, key) do
    {:ok, to_string(key), Map.pop!(map, key)}
  end

  defp pop_normal(map, key) when is_atom(key) do
    pop_normal(map, Atom.to_string(key))
  end

  defp pop_normal(map, key) when is_integer(key) do
    pop_normal(map, Integer.to_string(key))
  end

  defp pop_normal(_map, key) when is_binary(key) do
    :error
  end

  defp pop_normal(_map, key) do
    raise ArgumentError, "invalid key: #{inspect(key)}"
  end

  defp ensure_binary_key(key) when is_atom(key) do
    Atom.to_string(key)
  end

  defp ensure_binary_key(key) when is_binary(key) do
    key
  end

  defp ensure_binary_key(key) when is_integer(key) do
    Integer.to_string(key)
  end

  defp ensure_binary_key(key) do
    raise ArgumentError, "invalid key: #{inspect(key)}"
  end

  defp apply_caster(data, :default, ctx) do
    {to_json_decoded(data), ctx}
  end

  defp apply_caster(data, {:list, caster}, ctx) when is_list(data) do
    data
    |> Enum.with_index()
    |> Enum.map_reduce(ctx, fn {item, index}, ctx ->
      downpath(ctx, index, &apply_caster(item, caster, &1))
    end)
  end

  defp apply_caster(data, {:list, _caster}, ctx) do
    raise NormalizeError, ctx: ctx, reason: "expected a list but got: #{inspect(data)}"
  end

  defp apply_caster(data, {:map, caster}, ctx) when is_map(data) do
    {pairs, ctx} =
      Enum.map_reduce(data, ctx, fn {key, value}, ctx ->
        bin_key = ensure_binary_key(key)
        {value, ctx} = downpath(ctx, bin_key, &apply_caster(value, caster, &1))
        {{bin_key, value}, ctx}
      end)

    {Map.new(pairs), ctx}
  end

  defp apply_caster(data, {:map, _}, ctx) do
    raise NormalizeError,
      ctx: ctx,
      reason: raise(ArgumentError, "expected a map but got: #{inspect(data)}")
  end

  # with :or_ref we do not apply the cast if there is a reference
  defp apply_caster(data, {:or_ref, caster}, ctx) do
    case normalize_openapi_reference(data) do
      {:ok, refschema} -> {refschema, ctx}
      :error -> apply_caster(data, caster, ctx)
    end
  end

  defp apply_caster(data, module, ctx) when is_atom(module) do
    normalize!(data, module, ctx)
  end

  # checks if the given term is a reference provided by the users
  defp normalize_openapi_reference(term) when is_map(term) and not is_struct(term) do
    # $ref is allowed in schemas, and some entities only require a description,
    # while a Reference can also accept a description.
    #
    # So to determine if we are facing a reference we will check that the map only
    # contains $ref, summary and description keys and nothing else.

    with_normal_keys = Map.new(term, fn {k, v} -> {ensure_binary_key(k), v} end)

    if Map.has_key?(with_normal_keys, "$ref") and map_size(with_normal_keys) <= 3 and
         Enum.all?(Map.keys(with_normal_keys), &(&1 in ["$ref", "$summary", "description"])) do
      {:ok, to_json_decoded(with_normal_keys)}
    else
      :error
    end
  end

  defp normalize_openapi_reference(%{__struct__: Reference} = ref) do
    {:ok, ref}
  end

  defp normalize_openapi_reference(_) do
    :error
  end

  def to_json_decoded(data) do
    {data, _acc} = JSV.Normalizer.normalize(data, [], [])
    data
  end

  # Normalizing schemas
  #
  # When normalizing, schemas that are given as module names are expanded by
  # calling the schema/0 function in the module and adding the result in the
  # context for later addition to the #/components/schemas collection.
  #
  # The atom is replaced in its original location by a map schema with a $ref to
  # that component.

  defp do_normalize_schema(struct, ctx) when is_struct(struct) do
    struct
    |> JSV.Normalizer.Normalize.normalize()
    |> do_normalize_schema(ctx)
  end

  defp do_normalize_schema(map, ctx) when is_map(map) do
    {pairs, ctx} =
      Enum.map_reduce(map, ctx, fn {k, v}, ctx ->
        {v, ctx} = do_normalize_schema(v, ctx)
        {{ensure_binary_key(k), v}, ctx}
      end)

    {Map.new(pairs), ctx}
  end

  defp do_normalize_schema(scalar, ctx)
       when is_binary(scalar)
       when is_number(scalar)
       when is_boolean(scalar)
       when is_nil(scalar) do
    {scalar, ctx}
  end

  defp do_normalize_schema(module, ctx) when is_map_key(ctx.seen_schema_mods, module) do
    name = Map.fetch!(ctx.seen_schema_mods, module)
    replacement = %{"$ref" => ref_to_schema(name)}
    {replacement, ctx}
  end

  defp do_normalize_schema(atom, ctx) when is_atom(atom) do
    if JSV.Schema.schema_module?(atom) do
      normalize_module_schema(atom, ctx)
    else
      {Atom.to_string(atom), ctx}
    end
  end

  defp do_normalize_schema(list, ctx) when is_list(list) do
    Enum.map_reduce(list, ctx, &do_normalize_schema/2)
  end

  defp normalize_module_schema(module, ctx) do
    # * First derive a name from the schema title, and set it as seen
    #   in the context.
    # * Then recurse on the schema to also turn nested atoms in
    #   references before storing the normal schema in context.
    # * Then return a reference.
    schema = module.schema()
    title = schema_title(schema, module)
    name = available_schema_name(ctx.schemas, title)

    ctx = %{ctx | seen_schema_mods: Map.put(ctx.seen_schema_mods, module, name)}

    # Recursion
    {normal_schema, ctx} = do_normalize_schema(schema, ctx)

    ctx = %{ctx | schemas: Map.put(ctx.schemas, name, normal_schema)}

    replacement = %{"$ref" => ref_to_schema(name)}
    {replacement, ctx}
  end

  defp ref_to_schema(name) do
    "#/components/schemas/#{name}"
  end

  defp schema_title(%{"title" => title}, _module) when is_binary(title) and title != "" do
    title
  end

  defp schema_title(%{title: title}, _module) when is_binary(title) and title != "" do
    title
  end

  defp schema_title(_schema, module) do
    inspect(module)
  end

  defp available_schema_name(schemas, title) do
    if Map.has_key?(schemas, title) do
      available_schema_name(schemas, title, 1)
    else
      title
    end
  end

  defp available_schema_name(schemas, title, n) do
    name = "#{title}_#{Integer.to_string(n)}"

    if Map.has_key?(schemas, title) do
      available_schema_name(schemas, title, n + 1)
    else
      name
    end
  end
end
