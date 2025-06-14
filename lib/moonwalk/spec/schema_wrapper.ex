defmodule Moonwalk.Spec.SchemaWrapper do
  require JSV
  use Moonwalk.Internal.SpecObject

  # Allows definition of input and output data types.
  def schema do
    %{
      title: "SchemaWrapper",
      description: "Allows definition of input and output data types."
    }
  end
end
