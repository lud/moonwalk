defmodule Moonwalk.Spec.SchemaWrapper do
  require JSV
  use Moonwalk.Spec

  # Accepts anything to support module names as schemas.
  def schema do
    JSV.Schema.normalize(%{title: "SchemaWrapper"})
  end
end
