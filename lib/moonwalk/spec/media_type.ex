defmodule Moonwalk.Spec.MediaType do
  import Moonwalk.Spec

  @enforce_keys [:schema]
  defstruct schema: nil, examples: []

  @always_schema JSV.build!(true)
  @never_schema JSV.build!(false)

  def build!(spec, opts) do
    default_examples =
      case Access.fetch(spec, :example) do
        {:ok, example} -> [example]
        :error -> []
      end

    spec
    |> make(:operation)
    |> take_required(:schema, &build_schema(&1, opts))
    |> take_default(:examples, default_examples)
    |> into(__MODULE__)
  end

  defp build_schema(true, _opts) do
    {:ok, @always_schema}
  end

  defp build_schema(false, _opts) do
    {:ok, @never_schema}
  end

  defp build_schema(schema, _opts) do
    JSV.build(schema)
  end
end
