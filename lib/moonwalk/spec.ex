defmodule Moonwalk.Spec do
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

  def update({target, input, output}, key, update) when is_function(update, 1) do
    {_, output} = Access.get_and_update(output, key, fn v -> {v, update.(v)} end)

    {target, input, output}
  end

  def into({target, _, output}) do
    struct!(target, output)
  end
end
