defmodule Moonwalk.Schema.Subschema do
  @moduledoc false
  defstruct [:validators]
end

defmodule Moonwalk.Schema do
  alias __MODULE__
  alias Moonwalk.Schema.BooleanSchema
  alias Moonwalk.Schema.Builder
  alias Moonwalk.Schema.Key
  alias Moonwalk.Schema.Resolver
  alias Moonwalk.Schema.Validator

  defstruct validators: %{}, root_key: nil
  @opaque t :: %__MODULE__{}

  @default_draft_default "https://json-schema.org/draft/2020-12/schema"

  def validate(data, schema) do
    case validation_entrypoint(data, schema) do
      {:ok, casted_data, _} -> {:ok, casted_data}
      {:error, %Validator{} = _validator} = err -> err
    end
  end

  @doc false
  # entrypoint for tests when we want to return the validator struct
  def validation_entrypoint(data, schema) do
    %__MODULE__{validators: validators, root_key: root_key} = schema
    root_schema_validators = Map.fetch!(validators, root_key)
    Validator.validate(data, root_schema_validators, Validator.new(schema))
  end

  def build(raw_schema, opts) when is_map(raw_schema) do
    {resolver_impl, opts} = Keyword.pop!(opts, :resolver)
    {default_draft, opts} = Keyword.pop(opts, :default_draft, @default_draft_default)

    resolver_opts = %{resolver: resolver_impl, default_draft: default_draft}

    with {:ok, resolver} <- Resolver.new_root(raw_schema, resolver_opts),
         bld = Builder.new(resolver: resolver, opts: opts),
         bld = Builder.stage_build(bld, resolver.root),
         root_key = Key.of(resolver.root),
         {:ok, validators} <- Builder.build_all(bld) do
      {:ok, %Schema{validators: validators, root_key: root_key}}
    end
  end

  def build(valid?, _opts) when is_boolean(valid?) do
    {:ok, %Schema{root_key: :root, validators: %{root: BooleanSchema.of(valid?)}}}
  end
end
