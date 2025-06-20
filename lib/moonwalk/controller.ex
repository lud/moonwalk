defmodule Moonwalk.Controller do
  alias Moonwalk.Spec.Operation

  defmacro __using__(opts) do
    quote bind_quoted: binding() do
      import Moonwalk.Controller

      Module.register_attribute(__MODULE__, :moonwalk_operations, accumulate: true)

      @before_compile Moonwalk.Controller
    end
  end

  defmacro operation(action, spec \\ [])

  # TODO(doc) when using the {schema, opts} syntax, the :required option of a
  # request body is set to true by default.
  defmacro operation(action, false) do
    quote do
      @moonwalk_operations {unquote(action), false}
    end
  end

  defmacro operation(action, spec) when is_atom(action) and is_list(spec) do
    spec = ensure_operation_id(spec, action, __CALLER__)

    quote bind_quoted: binding() do
      operation = Moonwalk.Spec.Operation.from_controller!(spec)
      @moonwalk_operations {action, operation}
    end
  end

  # TODO(doc) used to reference operations given by an external spec
  defmacro use_operation(action, operation_id) do
    quote bind_quoted: binding() do
      @moonwalk_operations {action, {:use_operation, to_string(operation_id)}}
    end
  end

  defp ensure_operation_id(spec, action, env) do
    case Keyword.fetch(spec, :operation_id) do
      {:ok, atom} when is_atom(atom) -> Keyword.put(spec, :operation_id, Atom.to_string(atom))
      {:ok, str} when is_binary(str) -> spec
      :error -> Keyword.put(spec, :operation_id, operation_id_from_env(action, env))
    end
  end

  defp operation_id_from_env(action, env) do
    controller_name =
      env.module
      |> Atom.to_string()
      |> case do
        "Elixir." <> rest -> rest
        str -> str
      end
      |> Phoenix.Naming.unsuffix("Controller")

    # id prefix is the last part of the controller name
    id_prefix =
      controller_name
      |> String.split(".")
      |> List.last()
      |> Macro.underscore()

    # Hash the controller name to allow multiple controllers to have the same ID
    # prefix, for instance "Api.V1.User" and "Api.V2.User". Collisions can
    # happen but users are supposed to provide their own operation ids.
    mod_hash =
      controller_name
      |> then(&<<:erlang.phash2(&1, 2 ** 32)::little-32>>)
      |> Base.encode32(padding: false)

    "#{id_prefix}_#{to_string(action)}_#{mod_hash}"
  end

  defmacro __before_compile__(env) do
    moonwalk_operations = Module.delete_attribute(env.module, :moonwalk_operations) || []

    clauses =
      Enum.map(moonwalk_operations, fn {action, operation} ->
        case operation do
          false ->
            Moonwalk.Controller._ignore_action(action)

          %Operation{} ->
            Moonwalk.Controller._define_operation(action, operation)

          {:use_operation, operation_id} ->
            Moonwalk.Controller._define_operation(action, {:use_operation, operation_id})
        end
      end)

    quote do
      @doc false
      def __moonwalk__(kind, action, arg)

      unquote(clauses)

      # undef catchall
      def __moonwalk__(kind, action, arg) do
        :__undef__
      end
    end
  end

  @doc false
  def _ignore_action(action) do
    quote do
      def __moonwalk__(_kind, unquote(action), _method) do
        :ignore
      end
    end
  end

  @doc false
  def _define_operation(action, %Operation{} = operation) when is_atom(action) do
    operation_id = operation.operationId
    operation = Macro.escape(operation)

    quote bind_quoted: binding() do
      @doc false

      # This is used by Paths.from_router / Paths.from_routes to retrieve
      # operations defined with the operation macro.
      def __moonwalk__(:operation, unquote(action), _method) do
        {:ok, unquote(Macro.escape(operation))}
      end

      # This is used by the ValidateRequest plug to retrieve the operation from
      # the phoenix controller/action.
      def __moonwalk__(:operation_id, unquote(action), _method) do
        {:ok, unquote(operation_id)}
      end
    end
  end

  def _define_operation(action, {:use_operation, operation_id}) do
    quote bind_quoted: binding() do
      @doc false

      # This is used by the ValidateRequest plug to retrieve the operation from
      # the phoenix controller/action.
      def __moonwalk__(:operation_id, unquote(action), _method) do
        {:ok, unquote(operation_id)}
      end
    end
  end
end
