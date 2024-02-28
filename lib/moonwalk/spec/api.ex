defmodule Moonwalk.Spec.Api do
  defstruct [:openapi, :info]

  def define(opts) do
    opts
    |> validate_opts!()
    |> Enum.reduce(%{}, &collect_opt/2)
    |> Map.put_new(:openapi, "4.0.0")
    |> then(&struct!(__MODULE__, &1))
  end

  # TODO use self schema
  defp validate_opts!(opts) do
    opts
  end

  defp collect_opt({:title, title}, acc) do
    Map.update(acc, :info, %{title: title}, &Map.put(&1, :title, title))
  end

  def normalize_spec(api) do
    api
    |> Map.from_struct()
    |> Enum.reduce(%{}, fn
      {_, nil}, acc -> acc
      pair, acc -> normalize(pair, acc)
    end)
  end

  defp normalize({:info, info}, raw) when is_map(info) do
    Map.put(raw, "info", Enum.reduce(info, %{}, &normalize/2))
  end

  defp normalize({:title, title}, raw) do
    Map.put(raw, "title", title)
  end

  defp normalize({:openapi, vsn}, raw) do
    Map.put(raw, "openapi", vsn)
  end
end
