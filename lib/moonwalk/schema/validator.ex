defmodule Moonwalk.Schema.Validator.Error do
  # @derive {Inspect, only: [:resolver, :staged]}
  defstruct [:kind, :data, :args, :formatter]

  @opaque t :: %__MODULE__{}

  def new(kind, data, formatter \\ nil, args) do
    %__MODULE__{kind: kind, data: data, formatter: formatter, args: args}
  end
end

defmodule Moonwalk.Schema.Validator.Context do
  alias Moonwalk.Schema.Validator.Error
  defstruct [:path, :validators, :scope]

  @opaque t :: %__MODULE__{}

  def new(validators, root_scope) do
    %__MODULE__{path: [], validators: validators, scope: [root_scope]}
  end

  def downpath(%{path: path} = ctx, key) do
    %__MODULE__{ctx | path: [key | path]}
  end

  def checkout_ref(%{scope: scope} = ctx, {:dynamic_anchor, ns, anchor}) do
    case checkout_dynamic_ref(scope, ctx, anchor) do
      :error -> checkout_ref(ctx, {:anchor, ns, anchor})
      {:ok, v} -> v
    end
  end

  def checkout_ref(%{validators: vds}, vkey) do
    Map.fetch!(vds, vkey)
  end

  defp checkout_dynamic_ref([nil | scope], ctx, anchor) do
    checkout_dynamic_ref(scope, ctx, anchor)
  end

  defp checkout_dynamic_ref([h | scope], ctx, anchor) do
    with :error <- checkout_dynamic_ref(scope, ctx, anchor) do
      Map.fetch(ctx.validators, {:dynamic_anchor, h, anchor})
    end
  end

  defp checkout_dynamic_ref([], _, _) do
    :error
  end

  def append_scope(%__MODULE__{scope: scope} = ctx, segment) do
    %__MODULE__{ctx | scope: [segment | scope]}
  end

  @deprecated "use make_error"
  def type_error(_ctx, data, type) do
    Error.new(:type, data, type: type)
  end

  def group_error(_ctx, data, errors) do
    Error.new(:group, data, Error, errors: errors)
  end

  def boolean_schema_error(_ctx) do
    Error.new(:boolean_schema, nil, Error, [])
  end

  defmacro make_error(ctx, kind, data, args) do
    quote bind_quoted: binding() do
      Moonwalk.Schema.Validator.Context.__make_error__(ctx, kind, data, __MODULE__, args)
    end
  end

  def __make_error__(_ctx, kind, data, formatter, args) do
    Error.new(kind, data, formatter, args)
  end
end

defmodule Moonwalk.Schema.Validator do
  alias Moonwalk.Helpers
  alias Moonwalk.Schema.BooleanSchema
  alias Moonwalk.Schema
  alias Moonwalk.Schema.Validator.Context

  def validate(data, %Schema{} = schema) do
    %{validators: validators, root_key: root_key} = schema
    ctx = Moonwalk.Schema.Validator.Context.new(validators, root_key)

    # TODO force pass a downpath segment register evaluated items and properties
    # in the context
    #
    # Otherwise see if a vocalbulary can know if another vocabulary is being used
    # and implement unevaluatedProperties in the applicator
    root_validator = Map.fetch!(validators, root_key)
    validate_sub(data, root_validator, ctx)
  end

  def validate_sub(data, %BooleanSchema{} = bs, ctx) do
    case BooleanSchema.valid?(bs) do
      true -> {:ok, data}
      false -> {:error, Context.boolean_schema_error(ctx)}
    end
  end

  def validate_sub(data, {:alias_of, key}, ctx) do
    validate_sub(data, Map.fetch!(ctx.validators, key), ctx)
  end

  IO.warn("remove __scope__")

  def validate_sub(data, schema_validators, ctx) do
    ctx = Context.append_scope(ctx, schema_validators[:__scope__])

    Helpers.reduce_ok(schema_validators, data, fn
      {:__scope__, _}, data -> {:ok, data}
      {module, vds}, data -> module.validate(data, vds, ctx)
    end)
  end
end
