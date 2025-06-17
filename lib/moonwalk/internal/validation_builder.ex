defmodule Moonwalk.Internal.ValidationBuilder do
  alias JSV.Key
  alias JSV.Ref
  alias JSV.RNS
  alias Moonwalk.Internal.SpecValidator
  alias Moonwalk.Spec.Operation
  alias Moonwalk.Spec.Parameter
  alias Moonwalk.Spec.PathItem
  alias Moonwalk.Spec.Reference
  alias Moonwalk.Spec.RequestBody
  alias Moonwalk.Spec.Response

  def build_operations(normal_spec, opts \\ []) do
    spec = SpecValidator.validate!(normal_spec)

    to_build =
      spec.paths
      # TODO handle reference
      |> Enum.flat_map(fn {path, path_item} ->
        path_item
        |> deref(PathItem, _dummy_rev_path = [], spec)
        |> elem(0)
        |> Enum.map(fn {verb, operation} ->
          %Operation{operationId: operation_id} = operation
          {[verb, path, "paths"], operation_id, operation}
        end)
      end)

    jsv_ctx = JSV.build_init!(Keyword.get_lazy(opts, :jsv_opts, &jsv_opts/0))
    {_root_ns, _, jsv_ctx} = JSV.build_add!(jsv_ctx, normal_spec)

    {validations_by_op_id, jsv_ctx} =
      Enum.map_reduce(to_build, jsv_ctx, fn {rev_path, op_id, op}, jsv_ctx ->
        build_op_validation(rev_path, op_id, op, spec, jsv_ctx, opts)
      end)

    jsv_root = JSV.to_root!(jsv_ctx, :root)

    # TODO here we must ensure no duplicates in the map
    {to_ops_map(validations_by_op_id), jsv_root}
  end

  defp deref(%Reference{"$ref": "#/" <> bin_path = full_path}, expected, _rev_path, spec) do
    path = bin_path |> String.split("/") |> Enum.map(&maybe_to_existing_atom/1)

    case get_in(spec, path) do
      %^expected{} = found ->
        {found, :lists.reverse(path)}

      nil ->
        {nil, :lists.reverse(path)}

      other ->
        raise "could not dereference #{inspect(full_path)} (using #{inspect(path)}), " <>
                "expected struct #{inspect(expected)}, found #{inspect(other)}"
    end
  end

  defp deref(%mod{} = object, mod, rev_path, _spec) do
    {object, rev_path}
  end

  defp deref(nil, _, rev_path, _spec) do
    {nil, rev_path}
  end

  defp maybe_to_existing_atom(binary) when is_binary(binary) do
    String.to_existing_atom(binary)
  rescue
    _ in ArgumentError -> binary
  end

  defp to_ops_map(ops_list) do
    Enum.reduce(ops_list, %{}, fn
      {op_id, _}, acc when is_map_key(acc, op_id) -> raise ArgumentError, "duplicate operation id #{inspect(op_id)}"
      {op_id, op_spec}, acc -> Map.put(acc, op_id, op_spec)
    end)
  end

  defp jsv_opts do
    [
      default_meta: JSV.default_meta(),
      formats: [Moonwalk.JsonSchema.Formats | JSV.default_format_validator_modules()]
    ]
  end

  defp build_op_validation(rev_path, op_id, op, spec, jsv_ctx, opts) do
    validations = []

    # Body

    {validations, jsv_ctx} =
      case build_body_validation(op.requestBody, ["requestBody" | rev_path], spec, jsv_ctx) do
        {:no_validation, jsv_ctx} -> {validations, jsv_ctx}
        {required?, body_validations, jsv_ctx} -> {[{:body, required?, body_validations} | validations], jsv_ctx}
      end

    # Parameters

    {validations, jsv_ctx} =
      case build_parameters_validation(op.parameters, rev_path, spec, jsv_ctx) do
        {[], jsv_ctx} -> {validations, jsv_ctx}
        {parameters_by_location, jsv_ctx} -> {[{:parameters, parameters_by_location} | validations], jsv_ctx}
      end

    # Responses

    {validations, jsv_ctx} =
      case Keyword.get(opts, :responses) do
        true ->
          {resp_validations, jsv_ctx} = build_responses_validations(op.responses, rev_path, spec, jsv_ctx)
          {[{:responses, resp_validations} | validations], jsv_ctx}

        _ ->
          {validations, jsv_ctx}
      end

    {{op_id, validations}, jsv_ctx}
  end

  # -- Body Validation --------------------------------------------------------

  defp build_body_validation(%RequestBody{} = req_body, rev_path, _spec, jsv_ctx) when is_map(req_body) do
    {matchers, jsv_ctx} =
      req_body.content
      |> media_type_clauses()
      |> Enum.map_reduce(jsv_ctx, fn
        {original_media_type, media_matcher, media_spec}, jsv_ctx ->
          case media_spec do
            %{schema: true} ->
              {{media_matcher, :no_validation}, jsv_ctx}

            %{schema: nil} ->
              {{media_matcher, :no_validation}, jsv_ctx}

            %{schema: _schema} ->
              {schema, jsv_ctx} =
                build_schema_key(
                  ["schema", original_media_type, "content" | rev_path],
                  jsv_ctx
                )

              {{media_matcher, schema}, jsv_ctx}

            _ ->
              {{media_matcher, :no_validation}, jsv_ctx}
          end
      end)

    {req_body.required, matchers, jsv_ctx}
  end

  defp build_body_validation(%Reference{} = ref, rev_path, spec, jsv_ctx) do
    {request_body, body_rev_path} = deref(ref, RequestBody, rev_path, spec)
    build_body_validation(request_body, body_rev_path, spec, jsv_ctx)
  end

  defp build_body_validation(nil, _rev_path, _spec, jsv_ctx) do
    {:no_validation, jsv_ctx}
  end

  defp media_type_clauses(content_map) do
    content_map
    |> Enum.map(fn {media_type, media_spec} ->
      matcher = media_type_to_matcher(media_type)
      {media_type, matcher, media_spec}
    end)
    |> sort_media_type_clauses()
  end

  defp media_type_to_matcher(media_type) when is_binary(media_type) do
    case Plug.Conn.Utils.media_type(media_type) do
      :error -> {media_type, ""}
      {:ok, primary, secondary, _} -> {primary, secondary}
    end
  end

  defp sort_media_type_clauses(list) do
    Enum.sort_by(list, fn {_, {primary, secondary}, _} ->
      {media_priority(primary), media_priority(secondary), primary, secondary}
    end)
  end

  defp media_priority(type) do
    case type do
      "*" -> 2
      "" -> 1
      t when is_binary(t) -> 0
    end
  end

  # -- Parameters Validation --------------------------------------------------

  defp build_parameters_validation([], _rev_path, _spec, jsv_ctx) do
    {[], jsv_ctx}
  end

  defp build_parameters_validation(parameters, rev_path, spec, jsv_ctx) do
    {built_params, jsv_ctx} =
      parameters
      |> Enum.with_index()
      |> Enum.map(fn {p_or_ref, index} ->
        deref(p_or_ref, Parameter, [{:index, index}, "parameters" | rev_path], spec)
      end)
      |> Enum.flat_map_reduce(
        jsv_ctx,
        fn
          {%Parameter{in: p_in} = parameter, rev_path}, jsv_ctx when p_in in [:path, :query] ->
            {built_param, jsv_ctx} =
              build_parameter_validation(parameter, rev_path, jsv_ctx)

            {[built_param], jsv_ctx}

          {%Parameter{}, _}, jsv_ctx ->
            {[], jsv_ctx}
        end
      )

    built_params =
      built_params
      |> Enum.group_by(& &1.in)
      |> Enum.into(%{path: [], query: []})

    {built_params, jsv_ctx}
  end

  # TODO(doc) Document that the parameters names are generating atoms. As the
  # spec can be provided from raw JSON documents, it can be a problem if some
  # app is building validations on the fly. Maybe add an option to keep those as
  # binaries.
  defp build_parameter_validation(parameter, rev_path, jsv_ctx) do
    key = String.to_atom(parameter.name)

    {schema_key, jsv_ctx} =
      case parameter do
        %{schema: true} -> {:no_validation, jsv_ctx}
        %{schema: nil} -> {:no_validation, jsv_ctx}
        %{schema: schema} -> build_parameter_schema(schema, ["schema" | rev_path], jsv_ctx)
        _ -> {:no_validation, jsv_ctx}
      end

    built = %{
      bin_key: parameter.name,
      key: key,
      required: parameter_required(parameter),
      schema_key: schema_key,
      in: parameter.in
    }

    {built, jsv_ctx}
  end

  defp parameter_required(%Parameter{required: req?}) when is_boolean(req?) do
    req?
  end

  defp parameter_required(%Parameter{in: p_in}) do
    case p_in do
      :path -> true
      :query -> false
    end
  end

  defp build_parameter_schema(schema, rev_path, jsv_ctx) do
    # schema is already defined in the JSV build context, it is not given to the
    # builder. But it is used to check if we need to precast the values, as
    # params are always received as strings.
    precast = parameter_precast(schema, rev_path, :root, jsv_ctx)
    {jsv_key, jsv_ctx} = build_schema_key(rev_path, jsv_ctx)

    final_validator =
      case precast do
        {:precast, caster} -> {:precast, caster, jsv_key}
        :noprecast -> jsv_key
      end

    {final_validator, jsv_ctx}
  end

  defp parameter_precast(schema, rev_path, ns, jsv_ctx) do
    case schema do
      %{"type" => "integer"} ->
        {:precast, &JSV.Cast.string_to_integer/1}

      %{"type" => "boolean"} ->
        {:precast, &JSV.Cast.string_to_boolean/1}

      %{"type" => "number"} ->
        {:precast, &JSV.Cast.string_to_number/1}

      %{"type" => "array", "items" => %{"type" => "integer"}} ->
        {:precast, {:list, &JSV.Cast.string_to_integer/1}}

      %{"type" => "array", "items" => %{"type" => "boolean"}} ->
        {:precast, {:list, &JSV.Cast.string_to_boolean/1}}

      %{"type" => "array", "items" => %{"type" => "number"}} ->
        {:precast, {:list, &JSV.Cast.string_to_number/1}}

      %{"$ref" => _} = subschema ->
        parameter_precast_ref(subschema, rev_path, ns, jsv_ctx)

      _ ->
        :noprecast
    end
  end

  # If we want to support fetching parameters from refs we need to do it the
  # right way, _i.e_ JSV having support for fetching a ref recursively with NS
  # management, until we find a %{"type" => _} or no "$ref" anymore.
  #
  # The code below works but it does belong to JSV. For now this library does
  # not support precasting complex parameters and the users should expect a
  # string and do complex stuff on their side.
  #
  # I'm leaving the code as-is but instead of raising or warning we will just
  # silently ignore pre casting.
  #
  # Also JSV needs to expose the build context as a struct, currently we are
  # digging into a private record.
  defp parameter_precast_ref(%{"$ref" => ref} = subschema, rev_path, ns, jsv_ctx) do
    {:ok, sub_ns} =
      case subschema do
        %{"$id" => id} -> RNS.derive(ns, id)
        _ -> {:ok, ns}
      end

    ref = Ref.parse!(ref, sub_ns)
    {:build, builder, jsv_validators} = jsv_ctx
    new_builder = JSV.Builder.ensure_resolved!(builder, ref)
    key = Key.of(ref)
    resolved = JSV.Builder.fetch_resolved!(builder, key)
    {resolved.raw, sub_ns, {:build, new_builder, jsv_validators}}
  rescue
    _ -> :noprecast
  else
    {new_schema, new_ns, new_jsv_ctx} ->
      parameter_precast(new_schema, rev_path, new_ns, new_jsv_ctx)
  end

  # -- Responses Validation ---------------------------------------------------

  defp build_responses_validations(responses, rev_path, spec, jsv_ctx) do
    {validations, jsv_ctx} =
      Enum.map_reduce(responses, jsv_ctx, fn {code_str, resp_or_ref}, jsv_ctx ->
        {response, rev_path} = deref(resp_or_ref, Response, [code_str, "responses" | rev_path], spec)
        code = String.to_integer(code_str)
        resp_validation = build_response_validation(response, rev_path, jsv_ctx)
        {{code, resp_validation}, jsv_ctx}
      end)

    {Map.new(validations), jsv_ctx}
  end

  defp build_response_validation(response, rev_path, jsv_ctx) do
    {matchers, jsv_ctx} =
      response.content
      |> media_type_clauses()
      |> Enum.map_reduce(jsv_ctx, fn
        {original_media_type, media_matcher, media_spec}, jsv_ctx ->
          case media_spec do
            %{schema: true} ->
              {{media_matcher, :no_validation}, jsv_ctx}

            %{schema: nil} ->
              {{media_matcher, :no_validation}, jsv_ctx}

            %{schema: _schema} ->
              {schema, jsv_ctx} =
                build_schema_key(
                  ["schema", original_media_type, "content" | rev_path],
                  jsv_ctx
                )

              {{media_matcher, schema}, jsv_ctx}

            _ ->
              {{media_matcher, :no_validation}, jsv_ctx}
          end
      end)

    {matchers, jsv_ctx}
  end

  # -- Helpers ----------------------------------------------------------------

  defp build_schema_key(rev_path, jsv_ctx) do
    ref = rev_path_to_ref(rev_path, [])
    {_schema_key, _jsv_ctx} = JSV.build_key!(jsv_ctx, ref)
  end

  # Reverse the reversed path and ensure all keys are strings. This is
  # especially useful when dealing with references to the responses, as they are
  # under a numeric string key (like "200", "404", etc.).
  #
  # Parameters are true indexes, we have a special tuple for those.
  defp rev_path_to_ref([{:index, i} | t], acc) when is_integer(i) do
    rev_path_to_ref(t, [i | acc])
  end

  defp rev_path_to_ref([h | t], acc) when is_binary(h) do
    rev_path_to_ref(t, [h | acc])
  end

  defp rev_path_to_ref([h | t], acc) when is_atom(h) do
    rev_path_to_ref(t, [Atom.to_string(h) | acc])
  end

  defp rev_path_to_ref([], acc) do
    Ref.pointer!(acc, :root)
  end
end
