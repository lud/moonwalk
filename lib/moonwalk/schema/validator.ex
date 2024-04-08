defmodule Moonwalk.Schema.Validator.Error do
  # @derive {Inspect, only: [:resolver, :staged]}
  defstruct [:kind, :data, :args, :formatter]

  @opaque t :: %__MODULE__{}

  def new(kind, data, formatter \\ nil, args) do
    %__MODULE__{kind: kind, data: data, formatter: formatter, args: args}
  end
end

defmodule Moonwalk.Schema.Validator do
  alias Moonwalk.Schema.Key
  alias Moonwalk.Schema.Dialect
  alias Moonwalk.Helpers
  alias Moonwalk.Schema
  alias Moonwalk.Schema.BooleanSchema
  alias Moonwalk.Schema.Validator.Context
  alias Moonwalk.Schema.Validator.Error

  # TODO remove `%__MODULE__{}=`

  @enforce_keys [:path, :validators, :scope, :errors, :root_key, :public]
  defstruct @enforce_keys

  @opaque t :: %__MODULE__{}

  def new(%Schema{} = schema) do
    %{validators: validators, root_key: root_key} = schema
    %__MODULE__{path: [], validators: validators, root_key: root_key, scope: [root_key], errors: [], public: %{}}
  end

  def validate(data, dialect_or_boolean_schema, vdr)

  def validate(data, %BooleanSchema{} = bs, %__MODULE__{} = vdr) do
    case BooleanSchema.valid?(bs) do
      true -> return(data, vdr)
      false -> {:error, add_error(vdr, boolean_schema_error(bs))}
    end
  end

  def validate(data, {:alias_of, key}, %__MODULE__{} = vdr) do
    validate(data, Map.fetch!(vdr.validators, key), vdr)
  end

  def validate(data, validators, %__MODULE__{} = vdr) do
    do_validate(data, validators, vdr)
  end

  IO.warn("should set the scope from the ref, useless in validators")
  # Executes all validators with the given data, collecting errors on the way,
  # then return either ok or error with all errors.
  defp do_validate(data, %Dialect{} = dialect, vdr) do
    %{validators: validators, scope: inner_scope} = dialect

    %__MODULE__{scope: scopes} = vdr
    vdr = %__MODULE__{vdr | scope: [inner_scope | scopes]}

    applied =
      apply_all_fun(data, validators, vdr, fn data, {module, mod_validators}, vdr ->
        module.validate(data, mod_validators, vdr)
      end)

    case applied do
      {:ok, data, vdr} -> {:ok, data, %__MODULE__{vdr | scope: scopes}}
      {:error, vdr} -> {:error, %__MODULE__{vdr | scope: scopes}}
    end
  end

  def apply_all_fun(data, validators, vdr, fun) do
    {new_data, new_vdr} =
      Enum.reduce(validators, {data, vdr}, fn validation_item, {data, vdr} ->
        case fun.(data, validation_item, vdr) do
          # When returning :ok, the errors may be empty or not, depending on
          # previous iterations.
          {:ok, new_data, %__MODULE__{} = new_vdr} ->
            {new_data, new_vdr}

          # When returning :error, an error MUST be set
          {:error, %__MODULE__{errors: [_ | _]} = new_vdr} ->
            {data, new_vdr}

          other ->
            raise "Invalid return from #{inspect(fun)} called with #{inspect(validation_item)}: #{inspect(other)}"
        end
      end)

    return(new_data, new_vdr)
  end

  def validate_nested(data, key, subvalidators, vdr) when is_binary(key) when is_integer(key) do
    %__MODULE__{path: path, validators: all_validators, scope: scope, root_key: root_key} = vdr
    # We do not carry sub errors so custom validation do not have to check for
    # error presence when iterating with map/reduce (although they should use
    # apply_all_funs).
    sub_vdr = %__MODULE__{
      path: [key | path],
      errors: [],
      validators: all_validators,
      scope: scope,
      root_key: root_key,
      public: %{}
    }

    case validate(data, subvalidators, sub_vdr) do
      {:ok, data, %__MODULE__{} = sub_vdr} -> {:ok, data, merge_sub(vdr, sub_vdr)}
      {:error, %__MODULE__{errors: [_ | _]} = sub_vdr} -> {:error, merge_sub(vdr, sub_vdr)}
    end
  end

  IO.warn("should set the scope from the ref, useless in validators")

  def validate_ref(data, ref, vdr) do
    subvalidators = checkout_ref(vdr, ref)

    %__MODULE__{path: path, validators: all_validators, scope: scope, root_key: root_key} = vdr
    # TODO separate validator must have its isolated evaluated paths list
    separate_vdr = %__MODULE__{
      path: path,
      errors: [],
      validators: all_validators,
      scope: [Key.namespace_of(ref) | scope],
      root_key: root_key,
      public: %{}
    }

    case validate(data, subvalidators, separate_vdr) do
      {:ok, data, %__MODULE__{} = separate_vdr} -> {:ok, data, merge_sub(vdr, separate_vdr)}
      {:error, %__MODULE__{errors: [_ | _]} = separate_vdr} -> {:error, merge_sub(vdr, separate_vdr)}
    end
  end

  defp merge_sub(vdr, sub) do
    %__MODULE__{errors: vdr_errors} = vdr
    %__MODULE__{errors: sub_errors} = sub
    %__MODULE__{vdr | errors: merge_errors(vdr_errors, sub_errors)}
  end

  defp merge_errors([], sub_errors) do
    sub_errors
  end

  defp merge_errors(vdr_errors, []) do
    vdr_errors
  end

  defp merge_errors(vdr_errors, sub_errors) do
    # TODO maybe append but for now we will flatten only when rendering/formatting errors
    [vdr_errors, sub_errors]
  end

  def return(data, %__MODULE__{errors: []} = vdr) do
    {:ok, data, vdr}
  end

  def return(_data, %__MODULE__{errors: [_ | _]} = vdr) do
    {:error, vdr}
  end

  def checkout_ref(%{scope: scope} = vdr, {:dynamic_anchor, ns, anchor}) do
    case checkout_dynamic_ref(scope, vdr, anchor) do
      :error -> checkout_ref(vdr, {:anchor, ns, anchor})
      {:ok, v} -> v
    end
  end

  def checkout_ref(%{validators: vds}, vkey) do
    Map.fetch!(vds, vkey)
  end

  defp checkout_dynamic_ref([nil | scope], vdr, anchor) do
    checkout_dynamic_ref(scope, vdr, anchor)
  end

  defp checkout_dynamic_ref([h | scope], vdr, anchor) do
    with :error <- checkout_dynamic_ref(scope, vdr, anchor) do
      Map.fetch(vdr.validators, {:dynamic_anchor, h, anchor})
    end
  end

  defp checkout_dynamic_ref([], _, _) do
    :error
  end

  @deprecated "use make_error"
  def type_error(_vdr, data, type) do
    Error.new(:type, data, type: type)
  end

  def group_error(_vdr, data, errors) do
    Error.new(:group, data, Error, errors: errors)
  end

  def boolean_schema_error(%BooleanSchema{valid?: false}) do
    Error.new(:boolean_schema, nil, Error, valid?: false)
  end

  defmacro return_error(data, vdr, kind, args) do
    quote bind_quoted: binding() do
      {:error, Moonwalk.Schema.Validator.__with_error__(__MODULE__, data, vdr, kind, args)}
    end
  end

  defmacro with_error(vdr, kind, data, args) do
    quote bind_quoted: binding() do
      Moonwalk.Schema.Validator.__with_error__(__MODULE__, vdr, kind, data, args)
    end
  end

  @doc false
  def __with_error__(module, %__MODULE__{} = vdr, kind, data, args) do
    error = Error.new(kind, data, module, args)
    add_error(vdr, error)
  end

  def __with_error__(module, data, %__MODULE__{} = vdr, kind, args) do
    raise("use vdr,kind,data arg order")
    __with_error__(module, vdr, kind, data, args)
  end

  defp add_error(vdr, error) do
    %__MODULE__{errors: errors, path: path} = vdr
    %__MODULE__{vdr | errors: [{path, error} | errors]}
  end

  IO.warn("remove make_error")

  defmacro make_error(vdr, kind, data, args) do
    IO.warn("deprecated make_error")

    quote bind_quoted: binding() do
      Moonwalk.Schema.Validator.Context.__make_error__(vdr, kind, data, __MODULE__, args)
    end
  end

  def __make_error__(_vdr, kind, data, formatter, args) do
    Error.new(kind, data, formatter, args)
  end

  # def put_path_meta(%__MODULE__{} = vdr, key, value) do
  #   %{path: path, public: public} = vdr
  #   full_key = {path, key}
  #   public = Map.put(public, full_key, value)
  #   %__MODULE__{vdr | public: public}
  # end

  # def get_path_meta(%__MODULE__{} = vdr, key) do
  #   %{path: path, public: public} = vdr
  #   full_key = {path, key}
  #   Map.fetch(public, full_key)
  # end
end
