defmodule Moonwalk.Controller do
  alias Moonwalk.Spec.Operation
  alias Moonwalk.Spec.RequestBody

  defmacro __using__(opts) do
    quote bind_quoted: binding() do
      opts =
        Keyword.put_new_lazy(opts, :pretty_errors, fn ->
          if function_exported?(Mix, :env, 0) do
            Mix.env() != :prod
          else
            false
          end
        end)

      @moonwalk_opts opts

      @doc false
      def __moonwalk__(:opts) do
        @moonwalk_opts
      end

      import Moonwalk.Controller

      Module.register_attribute(__MODULE__, :moonwalk_actions, accumulate: true)

      @before_compile Moonwalk.Controller
    end
  end

  defmacro operation(action, spec \\ [])

  defmacro operation(action, false) do
    quote do
      @moonwalk_actions {unquote(action), false}
    end
  end

  defmacro operation(action, spec) when is_atom(action) and is_list(spec) do
    spec = ensure_operation_id(spec, action, __CALLER__)

    quote bind_quoted: binding() do
      operation = Moonwalk.Spec.Operation.build!(spec, [])
      @moonwalk_actions {action, operation}
    end
  end

  defp ensure_operation_id(spec, action, env) do
    case Keyword.fetch(spec, :operation_id) do
      {:ok, _} -> spec
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

    controller_name <> "_" <> to_string(action)
  end

  defmacro __before_compile__(_env) do
    quote unquote: false do
      @doc false
      def __moonwalk__(action, kind, match_value)

      Moonwalk.Controller.define_operations()
    end
  end

  defmacro define_operations do
    moonwalk_actions = Module.delete_attribute(__CALLER__.module, :moonwalk_actions) || []

    clauses =
      Enum.map(moonwalk_actions, fn {action, operation} ->
        case operation do
          false -> Moonwalk.Controller.ignore_action(action)
          %Operation{} -> Moonwalk.Controller.define_operation(action, operation)
        end
      end)

    quote do
      unquote(clauses)

      # undef catchall
      def __moonwalk__(action, kind, arg) do
        :__undef__
      end
    end
  end

  @doc false
  def ignore_action(action) do
    quote do
      def __moonwalk__(unquote(action), :handle_action?, _method) do
        false
      end
    end
  end

  def define_operation(action, operation) when is_atom(action) do
    operation = Macro.escape(operation)

    quote bind_quoted: binding() do
      def __moonwalk__(unquote(action), :handle_action?, _method) do
        true
      end

      case operation.request_body do
        nil ->
          def __moonwalk__(unquote(action), :validate_body?, _method) do
            false
          end

        %RequestBody{content: map} when is_map(map) ->
          def __moonwalk__(unquote(action), :validate_body?, _method) do
            true
          end

          map
          |> Moonwalk.Controller.media_type_clauses()
          |> Enum.each(fn
            {match_ast, media_spec} ->
              def __moonwalk__(unquote(action), :request_body_schema, unquote(match_ast)) do
                {:ok, unquote(Macro.escape(media_spec.schema))}
              end
          end)

          def __moonwalk__(unquote(action), :request_body_schema, _) do
            :error
          end
      end
    end
  end

  @doc false
  def media_type_clauses(content_map) do
    content_map
    |> Enum.map(fn {mime_type, media_spec} ->
      {:ok, primary, secondary, _} = Plug.Conn.Utils.media_type(mime_type)
      {{primary, secondary}, media_spec}
    end)
    |> sort_media_type_clauses()
    |> Enum.map(fn {{primary, secondary}, media_spec} ->
      match_ast = Moonwalk.Controller.schema_signature({primary, secondary})
      {match_ast, media_spec}
    end)
  end

  defp sort_media_type_clauses(list) do
    Enum.sort_by(list, fn {{primary, secondary}, _} ->
      sort_primary = (primary == "*" && 1) || 0
      sort_secondary = (secondary == "*" && 1) || 0
      {sort_primary, sort_secondary, {primary, secondary}}
    end)
  end

  @doc false
  def schema_signature({primary, secondary}) do
    case {primary, secondary} do
      {"*", _} ->
        quote do
          _
        end

      {_, "*"} ->
        quote do
          {unquote(primary), _}
        end

      _ ->
        quote do
          {unquote(primary), unquote(secondary)}
        end
    end
  end
end
