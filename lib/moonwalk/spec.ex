defmodule Moonwalk.Spec do
  @moduledoc false

  defmacro __using__(_) do
    # placeholder for future functionality
    # TODO replace `use` by `import` if not used
    quote do
      import unquote(__MODULE__)
    end
  end

  @undef :__undefined__
  def make(opts, target) do
    {target, opts, %{}}
  end

  def nocast(value) do
    {:ok, value}
  end

  defp with_cast(target, input, output, key, value, caster) do
    case cast(value, caster) do
      {:ok, cast_value} ->
        {target, input, Map.put(output, key, cast_value)}

      {:error, errmsg} when is_binary(errmsg) ->
        raise ArgumentError,
          message:
            "could not cast key #{inspect(key)} when building #{inspect(target)}, got: #{errmsg}"
    end
  end

  defp cast(value, {caster, errmsg}) when is_function(caster, 1) do
    cast(value, caster, errmsg)
  end

  defp cast(value, caster) when is_function(caster, 1) do
    cast(value, caster, "invalid value")
  end

  # cast value expect result tuples because we may want to use generic casts
  # from other libraries. But the whole spec building otherwise just raises
  # exceptions.
  defp cast(value, caster, errmsg) do
    case caster.(value) do
      {:ok, _} = fine -> fine
      {:error, reason} -> {:error, "#{errmsg}, #{inspect(reason)}, value: #{inspect(value)}"}
    end
  end

  defp pop(container, key) when is_map(container) do
    case Map.pop(container, key, @undef) do
      {@undef, _} -> :error
      {value, container} -> {:ok, value, container}
    end
  end

  defp pop(container, key) when is_list(container) do
    case Keyword.pop(container, key, @undef) do
      {@undef, _} -> :error
      {value, container} -> {:ok, value, container}
    end
  end

  defp set(container, key, value) when is_list(container) do
    Keyword.put(container, key, value)
  end

  defp set(container, key, value) when is_map(container) do
    Map.put(container, key, value)
  end

  def put({target, input, output}, key, value) when is_atom(key) do
    {target, input, set(output, key, value)}
  end

  def rename_input({target, input, output}, inkey, outkey) do
    case pop(input, inkey) do
      {:ok, value, input} -> {target, set(input, outkey, value), output}
      :error -> {target, input, output}
    end
  end

  def take_required({target, input, output}, key, cast \\ &nocast/1) do
    case pop(input, key) do
      {:ok, value, input} ->
        with_cast(target, input, output, key, value, cast)

      :error ->
        raise ArgumentError, "key #{inspect(key)} is required when building #{inspect(target)}"
    end
  end

  def take_default({target, input, output}, key, default, cast \\ &nocast/1) do
    case pop(input, key) do
      {:ok, value, input} -> with_cast(target, input, output, key, value, cast)
      :error -> {target, input, Map.put(output, key, default)}
    end
  end

  def into({target, _, output}) do
    struct!(target, output)
  end

  IO.warn("component expansion should be in its own module")

  @doc """
  Takes a `JSV` compatible schema and returns a new schema where the original
  schema and all other referenced schemas are moved under
  `#/components/<namespace>`.

  A $ref is generated to point to the original schema at the root of the
  returned map.

  Booleans are returned as-is.
  """
  def expand_components(boolean, _namespace) when is_boolean(boolean) do
    boolean
  end

  def expand_components(schema, namespace) when is_binary(namespace) do
    {new_schema, components} = expand_components(schema, %{namespace => %{}}, namespace)
    Map.put(new_schema, "components", components)
  end

  defp expand_components(boolean, components, _namespace) when is_boolean(boolean) do
    {boolean, components}
  end

  defp expand_components(schema, components, namespace) do
    normalizer_opts = [on_general_atom: &expand_module(&1, &2, namespace)]
    {schema, components} = JSV.Normalizer.normalize(schema, normalizer_opts, components)
    register_component_if_title(schema, components, namespace)
  end

  defp register_component_if_title(schema, components, namespace) do
    case schema do
      %{"title" => title} when is_binary(title) ->
        register_component(components, namespace, title, schema)

      _ ->
        {schema, components}
    end
  end

  defp expand_module(module, components, namespace) do
    if JSV.Schema.schema_module?(module) do
      schema = module.schema()
      {schema, components} = expand_components(schema, components, namespace)
      {schema, title} = enforce_title(schema, module)
      register_component(components, namespace, title, schema)
    else
      {Atom.to_string(module), components}
    end
  end

  defp enforce_title(schema, module) do
    case schema do
      %{"title" => title} when is_binary(title) ->
        {schema, title}

      %{} ->
        title = inspect(module)
        {Map.put(schema, "title", title), title}
    end
  end

  defp register_component(components, namespace, title, schema) do
    ref = "#/components/#{namespace}/#{title}"
    ref_schema = %{"$ref" => ref}

    case components do
      %{^namespace => %{^title => ^schema}} ->
        {ref_schema, components}

      %{^namespace => %{^title => other}} ->
        raise ArgumentError, """
        cannot reference two different schemas into #{inspect(ref)}

        NEW SCHEMA
        #{inspect(schema, pretty: true)}

        EXISTING SCHEMA
        #{inspect(other, pretty: true)}
        """

      %{^namespace => %{} = submap} ->
        submap = Map.put(submap, title, schema)
        {ref_schema, %{components | namespace => submap}}
    end
  end
end
