defmodule Moonwalk.Schema.Validator.Error do
  defstruct [:kind, :data, :args, :formatter]

  @opaque t :: %__MODULE__{}

  def new(kind, data, formatter \\ nil, args) do
    %__MODULE__{kind: kind, data: data, formatter: formatter, args: args}
  end
end

defmodule Moonwalk.Schema.Validator.Context do
  alias Moonwalk.Schema.Ref
  alias Moonwalk.Schema.Validator.Error
  defstruct [:path, :validators]

  @opaque t :: %__MODULE__{}

  def new(validators) do
    %__MODULE__{path: [], validators: validators}
  end

  def downpath(%{path: path} = ctx, key) do
    %__MODULE__{ctx | path: [key | path]}
  end

  def checkout_ref(%{validators: vds}, ref) do
    Map.fetch!(vds, Ref.to_key(ref))
  end

  defimpl Inspect do
    def inspect(%{path: path}, _opts) do
      "#Context<#{inspect(:lists.reverse(path))}>"
    end
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
  alias Moonwalk.Schema.BooleanSchema
  alias Moonwalk.Schema
  alias Moonwalk.Schema.Validator.Error
  alias Moonwalk.Schema.Validator.Context

  def validate(data, %Schema{validators: validators}) do
    ctx = Moonwalk.Schema.Validator.Context.new(validators)

    do_validate(data, ctx)
  end

  # TODO force pass a downpath segment register evaluated items and properties
  # in the context
  #
  # Otherwise see if a vocalbulary can know if another vocabulary is being used
  # and implement unevaluatedProperties in the applicator
  def do_validate(data, ctx) do
    validate_sub(data, Map.fetch!(ctx.validators, ctx.validators._root), ctx)
  end

  def validate_sub(data, %BooleanSchema{value: valid?}, ctx) do
    case valid? do
      true -> {:ok, data}
      false -> {:error, Context.boolean_schema_error(ctx)}
    end
  end

  def validate_sub(data, schema_validators, ctx) do
    Enum.reduce_while(schema_validators, {:ok, data}, fn {module, vds}, {:ok, data} ->
      case module.validate(data, vds, ctx) do
        {:ok, data} -> {:cont, {:ok, data}}
        {:error, _} = err -> {:halt, err}
      end
    end)
  end
end
