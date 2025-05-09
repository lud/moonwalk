defmodule Moonwalk.Spec.SchemaWrapper do
  import JSV
  use Moonwalk.Spec

  # Accepts anything to support module names as schemas.
  def schema,do: (%{    title: "SchemaWrapper", })
end
