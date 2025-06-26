defmodule Moonwalk.Controller do
  alias Moonwalk.Spec.Operation
  alias Moonwalk.Spec.Parameter

  defmacro __using__(opts) do
    quote bind_quoted: binding() do
      import Moonwalk.Controller
      Moonwalk.TestWeb.Helpers

      Module.register_attribute(__MODULE__, :moonwalk_parameters, accumulate: true)
      Module.register_attribute(__MODULE__, :moonwalk_tags, accumulate: true)
      Module.register_attribute(__MODULE__, :moonwalk_operations, accumulate: true)

      @before_compile Moonwalk.Controller
    end
  end

  defmacro operation(action, spec \\ [])

  # TODO(doc) when using the {schema, opts} syntax, the :required option of a
  # request body is set to true by default.
  #
  # TODO(doc) this makes the function ignored by moonwalk, as we cannot chose a
  # verb.
  defmacro operation(action, false) do
    quote do
      @moonwalk_operations {unquote(action), false, nil}
    end
  end

  defmacro operation(action, spec) when is_atom(action) and is_list(spec) do
    spec = maybe_expand_aliases(spec, __CALLER__)
    spec = ensure_operation_id(spec, action, __CALLER__)

    quote bind_quoted: binding() do
      {verb, spec} = Moonwalk.Controller.__pop_verb(spec)
      shared_parameters = :lists.reverse(Module.get_attribute(__MODULE__, :moonwalk_parameters, []))
      shared_tags = :lists.flatten(:lists.reverse(Module.get_attribute(__MODULE__, :moonwalk_tags, [])))

      operation =
        Moonwalk.Spec.Operation.from_controller!(spec, shared_parameters: shared_parameters, shared_tags: shared_tags)

      @moonwalk_operations {action, operation, verb}
    end
  end

  # TODO(doc) used to reference operations given by an external spec
  defmacro use_operation(action, operation_id, opts \\ []) do
    opts = maybe_expand_aliases(opts, __CALLER__)

    quote bind_quoted: binding() do
      {verb, opts} = Moonwalk.Controller.__pop_verb(opts)
      @moonwalk_operations {action, {:use_operation, to_string(operation_id)}, verb}
    end
  end

  # TODO(doc) document that parameters only apply to operations defined below
  # them in the module.
  defmacro parameter(key, opts) when is_atom(key) do
    opts = maybe_expand_aliases(opts, __CALLER__)

    quote bind_quoted: binding() do
      @moonwalk_parameters Parameter.from_controller!(key, opts)
    end
  end

  # TODO(doc) document that tags only apply to operations defined below them in
  # the module.
  defmacro tags(tags) when is_list(tags) do
    quote bind_quoted: binding() do
      @moonwalk_tags tags
    end
  end

  defp maybe_expand_aliases(ast, caller) do
    runtime? = Phoenix.plug_init_mode() == :runtime

    if runtime? && Macro.quoted_literal?(ast) do
      Macro.prewalk(ast, &expand_alias(&1, caller))
    else
      ast
    end
  end

  defp expand_alias({:__aliases__, _, _} = alias, env) do
    Macro.expand(alias, %{env | function: {:init, 2}})
  end

  defp expand_alias(other, _env) do
    other
  end

  defp ensure_operation_id(spec, action, env) do
    case Keyword.fetch(spec, :operation_id) do
      {:ok, atom} when is_atom(atom) -> Keyword.put(spec, :operation_id, Atom.to_string(atom))
      {:ok, str} when is_binary(str) -> spec
      {:ok, _} -> spec
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
    _ = Module.delete_attribute(env.module, :moonwalk_parameters)
    validate_duplicate_actions!(moonwalk_operations, env)

    clauses =
      Enum.map(moonwalk_operations, fn {action, operation, verb} ->
        case operation do
          false ->
            Moonwalk.Controller._ignore_action(action)

          %Operation{} ->
            Moonwalk.Controller._define_operation(action, operation, verb)

          {:use_operation, _} = using ->
            Moonwalk.Controller._define_operation(action, using, verb)
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
      def __moonwalk__(_kind, unquote(action), _verb) do
        :ignore
      end
    end
  end

  @doc false
  def _define_operation(action, %Operation{} = operation, verb) when is_atom(action) do
    operation_id = operation.operationId
    operation = Macro.escape(operation)

    quote bind_quoted: binding() do
      @doc false

      match_verb = Moonwalk.Controller.__verb_matcher(verb)

      # This is used by Paths.from_router / Paths.from_routes to retrieve
      # operations defined with the operation macro.
      def __moonwalk__(:operation, unquote(action), unquote(match_verb)) do
        {:ok, unquote(Macro.escape(operation))}
      end

      # This is used by the ValidateRequest plug to retrieve the operation from
      # the phoenix controller/action.
      def __moonwalk__(:operation_id, unquote(action), unquote(match_verb)) do
        {:ok, unquote(operation_id)}
      end
    end
  end

  def _define_operation(action, {:use_operation, operation_id}, verb) do
    quote bind_quoted: binding() do
      @doc false
      match_verb = Moonwalk.Controller.__verb_matcher(verb)

      # This is used by the ValidateRequest plug to retrieve the operation from
      # the phoenix controller/action.
      def __moonwalk__(:operation_id, unquote(action), unquote(match_verb)) do
        {:ok, unquote(operation_id)}
      end
    end
  end

  # Ensures that if multiple operations use the same controller function, a
  # :mehtod option is given to the `operation` or `use_operation` macro to be
  # able to match on it.
  defp validate_duplicate_actions!(moonwalk_operations, env) do
    bad_cases =
      moonwalk_operations
      |> Enum.filter(fn {_, definition, _verb} -> definition != false end)
      |> Enum.group_by(fn {action, _, _} -> action end, fn {_, op, verb} -> {op, verb} end)
      # Keep only groups with multiple operations on the same action, and where
      # at least one action does not provide the verb.
      |> Enum.flat_map(fn
        {_, []} ->
          []

        {_, [_]} ->
          []

        {action, [_, _ | _] = ops} ->
          without_verb = Enum.filter(ops, fn {_op, verb} -> verb == nil end)

          case without_verb do
            [] -> []
            rest -> [{action, rest}]
          end
      end)

    case bad_cases do
      [] ->
        :ok

      [{action, invalids} | _] ->
        op_ids = collect_op_ids(invalids)

        raise ArgumentError,
              "multiple operations defined for #{Exception.format_mfa(env.module, action, 2)}, " <>
                "please provide the :method option for operations #{inspect(op_ids)}"
    end
  end

  defp collect_op_ids(list) do
    Enum.map(list, fn
      {{:use_operation, op_id}, _verb} -> op_id
      {%Operation{operationId: op_id}, _verb} -> op_id
    end)
  end

  @doc false
  def __pop_verb(opts) do
    case Keyword.pop(opts, :method) do
      {nil, opts} -> {nil, opts}
      {v, opts} -> {validate_verb(v), opts}
    end
  end

  defp validate_verb(v) when not is_atom(v) do
    raise ArgumentError, "expected :method to be a lowercase atom, got: #{inspect(v)}"
  end

  defp validate_verb(v) do
    as_string = Atom.to_string(v)

    if String.downcase(as_string) != as_string do
      raise ArgumentError, "expected :method to be a lowercase atom, got: #{inspect(v)}"
    end

    v
  end

  # :post -> "POST" or _unused_var
  @doc false
  def __verb_matcher(nil) do
    Macro.var(:_any_verb, nil)
  end

  def __verb_matcher(verb) when is_atom(verb) do
    verb
  end
end
