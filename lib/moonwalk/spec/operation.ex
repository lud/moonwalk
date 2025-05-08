defmodule Moonwalk.Spec.Operation do
  alias Moonwalk.Spec.RequestBody
  import Moonwalk.Spec

  @enforce_keys [:operation_id]
  defstruct operation_id: nil,
            tags: [],
            description: nil,
            summary: nil,
            request_body: nil

  def build!(spec, opts \\ []) do
    {global_tags, opts} = Keyword.pop(opts, :tags, [])

    spec
    |> make(__MODULE__)
    |> take_required(:operation_id)
    |> take_default(:tags, [])
    |> take_default(:description, nil)
    |> take_default(:summary, nil)
    |> take_default(:request_body, nil, {&RequestBody.build(&1, opts), "invalid request body"})
    |> update(:tags, &(global_tags ++ &1))
    |> into()
  end
end
