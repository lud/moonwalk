defmodule Moonwalk.Controller do
  alias Moonwalk.SchemaBuilder
  alias Moonwalk.Spec.Operation
  alias Moonwalk.Spec.RequestBody

  defmacro __using__(opts) do
    quote bind_quoted: binding() do
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
      operation = Moonwalk.Spec.Operation.from_controller!(spec)
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
          false -> Moonwalk.Controller._ignore_action(action)
          %Operation{} -> Moonwalk.Controller._define_operation(action, operation)
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
  def _ignore_action(action) do
    quote do
      def __moonwalk__(unquote(action), _kind, _method) do
        :ignore
      end
    end
  end

  @doc false
  def _define_operation(action, operation) when is_atom(action) do
    operation = Macro.escape(operation)

    quote bind_quoted: binding() do
      validations = Moonwalk.Controller._define_validations(operation)

      @doc false
      def __moonwalk__(unquote(action), :validations, _method) do
        {:ok, unquote(Macro.escape(validations))}
      end

      def __moonwalk__(unquote(action), :operation, _method) do
        {:ok, unquote(Macro.escape(operation))}
      end
    end
  end

  @doc false
  def _define_validations(%Operation{} = operation) do
    parameters_validations =
      operation.parameters
      |> Enum.map(fn {key, parameter} ->
        bin_name = Atom.to_string(key)

        validation_root =
          case parameter.schema do
            true -> :no_validation
            schema -> SchemaBuilder.build(schema, cast_strings: true)
          end

        required? = parameter.required

        %{
          bin_key: bin_name,
          key: key,
          required: required?,
          schema: validation_root,
          in: parameter.in
        }
      end)
      |> Enum.group_by(& &1.in)
      |> Enum.into(%{path: [], query: []})
      |> then(fn by_location -> [parameters: by_location] end)

    [parameters: parameters_validations]

    body_validations =
      case operation.requestBody do
        nil ->
          []

        %RequestBody{content: content} when is_map(content) ->
          schema_clauses =
            content
            |> media_type_clauses()
            |> Enum.map(fn {matcher, media_spec} ->
              validation_root = build_expand_schema(media_spec.schema)

              {matcher, validation_root}
            end)

          [body: schema_clauses]
      end

    parameters_validations ++ body_validations
  end

  defp build_expand_schema(schema) do
    case schema do
      true ->
        :no_validation

      _ ->
        schema
        |> Moonwalk.Spec.expand_components("schemas")
        |> SchemaBuilder.build()
    end
  end

  defp media_type_clauses(content_map) do
    content_map
    |> Enum.map(fn {media_type, media_spec} ->
      {primary, secondary} = cast_media_type(media_type)
      {{primary, secondary}, media_spec}
    end)
    |> sort_media_type_clauses()
  end

  defp cast_media_type(media_type) when is_binary(media_type) do
    case Plug.Conn.Utils.media_type(media_type) do
      :error -> {media_type, ""}
      {:ok, primary, secondary, _} -> {primary, secondary}
    end
  end

  defp sort_media_type_clauses(list) do
    Enum.sort_by(list, fn {{primary, secondary}, _} ->
      {media_priority(primary), media_priority(secondary), primary, secondary}
    end)
  end

  defp media_priority("*") do
    2
  end

  defp media_priority("") do
    1
  end

  defp media_priority(m) when is_binary(m) do
    0
  end
end
