defmodule Moonwalk.Spec.SchemaWrapper do
  require JSV
  use Moonwalk.Spec

  # Allows definition of input and output data types, supporting any schema or module reference.
  def schema do
    JSV.Schema.normalize(%{
      title: "SchemaWrapper",
      description:
        "Allows definition of input and output data types, supporting any schema or module reference."
    })
  end
end
