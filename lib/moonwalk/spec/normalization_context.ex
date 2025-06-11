defmodule Moonwalk.Spec.NormalizationContext do
  @moduledoc false
  @enforce_keys [
    # A list of keys to track the current nesting path of the normalized tree
    :path,

    # A map of %{module => component name}. Component name is the last part of
    # the path in #/components/schemas/<component name>.
    #
    # When normalizing, if we see a module in a schema and the module is
    # already in here, we don't need to normalize the schema again.
    :seen_schema_mods,

    # A map of %{component name => normal schema}.
    :schemas
  ]
  defstruct @enforce_keys
  @type t :: %__MODULE__{}
end
