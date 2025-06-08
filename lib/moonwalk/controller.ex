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
      |> Module.split()
      |> List.last()
      |> Phoenix.Naming.unsuffix("Controller")
      |> Macro.underscore()

    # hash the controller name to allow multiple controllers to have the same
    # name, for instance "Api.V1.User" and "Api.V2.User". Collisions can happen
    # but users are supposed to provide operation ids.
    mod_hash = :erlang.phash2(env.module)

    "#{controller_name}_#{to_string(action)}_#{mod_hash}"
  end

  defmacro __before_compile__(env) do
    moonwalk_operations = Module.delete_attribute(env.module, :moonwalk_operations) || []

    clauses =
      Enum.map(moonwalk_operations, fn {action, operation} ->
        case operation do
          false -> Moonwalk.Controller._ignore_action(action)
          %Operation{} -> Moonwalk.Controller._define_operation(action, operation)
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
  def _define_operation(action, operation) when is_atom(action) do
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
end
