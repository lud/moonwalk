defmodule Moonwalk.Internal.ValidationBuilder do
  alias JSV.Key
  alias JSV.Ref
  alias JSV.RNS

  def build_operations(normal_spec) do
    to_build =
      normal_spec
      |> Map.get("paths", %{})
      |> Enum.flat_map(fn {path, verb_to_ops} ->
        Enum.map(verb_to_ops, fn {verb, operation} ->
          %{"operationId" => operation_id} = operation
          {[verb, path, "paths"], operation_id, operation}
        end)
      end)

    jsv_ctx = JSV.build_init!(jsv_opts())
    {_root_ns, _, jsv_ctx} = JSV.build_add!(jsv_ctx, normal_spec)

    {validations_by_op_id, jsv_ctx} =
      Enum.map_reduce(to_build, jsv_ctx, fn {rev_path, op_id, op}, jsv_ctx ->
        build_op_validation(rev_path, op_id, op, jsv_ctx)
      end)

    jsv_root = JSV.to_root!(jsv_ctx, :root)

    # TODO here we must ensure no duplicates in the map
    {to_ops_map(validations_by_op_id), jsv_root}
  end

  defp to_ops_map(ops_list) do
    Enum.reduce(ops_list, %{}, fn
      {op_id, _}, acc when is_map_key(acc, op_id) -> raise ArgumentError, "duplicate operation id #{inspect(op_id)}"
      {op_id, op_spec}, acc -> Map.put(acc, op_id, op_spec)
    end)
  end

  defp jsv_opts do
    []
  end

  defp build_op_validation(rev_path, op_id, op, jsv_ctx) do
    parameters = Map.get(op, "parameters", [])

    {validations, jsv_ctx} =
      case build_parameters_validation(parameters, rev_path, jsv_ctx) do
        {:no_validation, jsv_ctx} -> {[], jsv_ctx}
        {parameters_by_location, jsv_ctx} -> {[{:parameters, parameters_by_location}], jsv_ctx}
      end

    request_body = Map.get(op, "requestBody", nil)

    {validations, jsv_ctx} =
      case build_body_validation(request_body, rev_path, jsv_ctx) do
        {:no_validation, jsv_ctx} ->
          {validations, jsv_ctx}

        {required?, body_validations, jsv_ctx} ->
          {validations ++ [{:body, required?, body_validations}], jsv_ctx}
      end

    {{op_id, validations}, jsv_ctx}
  end

  defp build_parameters_validation([], _rev_path, jsv_ctx) do
    {:no_validation, jsv_ctx}
  end

  defp build_parameters_validation(parameters, rev_path, jsv_ctx) do
    {built_params, jsv_ctx} =
      parameters
      |> Enum.with_index()
      |> Enum.flat_map_reduce(
        jsv_ctx,
        fn
          {%{"in" => p_in} = parameter, index}, jsv_ctx when p_in in ["path", "query"] ->
            {built_param, jsv_ctx} =
              build_parameter_validation(parameter, [index, "parameters" | rev_path], jsv_ctx)

            {[built_param], jsv_ctx}

          _, jsv_ctx ->
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
    name = Map.fetch!(parameter, "name")

    p_in =
      case Map.fetch!(parameter, "in") do
        "path" -> :path
        "query" -> :query
      end

    key = String.to_atom(name)

    {schema_key, jsv_ctx} =
      case parameter do
        %{"schema" => true} -> {:no_validation, jsv_ctx}
        %{"schema" => nil} -> {:no_validation, jsv_ctx}
        %{"schema" => schema} -> build_parameter_schema(schema, ["schema" | rev_path], jsv_ctx)
        _ -> {:no_validation, jsv_ctx}
      end

    built = %{
      bin_key: name,
      key: key,
      required: Map.get(parameter, "required") == true,
      schema_key: schema_key,
      in: p_in
    }

    {built, jsv_ctx}
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

  defp build_body_validation(%{} = req_body, rev_path, jsv_ctx) when is_map(req_body) do
    required? = Map.get(req_body, "required", false)
    content = Map.fetch!(req_body, "content")

    {matchers, jsv_ctx} =
      content
      |> media_type_clauses()
      |> Enum.map_reduce(jsv_ctx, fn
        {original_media_type, media_matcher, media_spec}, jsv_ctx ->
          case media_spec do
            %{"schema" => true} ->
              {{media_matcher, :no_validation}, jsv_ctx}

            %{"schema" => nil} ->
              {{media_matcher, :no_validation}, jsv_ctx}

            %{"schema" => _schema} ->
              {schema, jsv_ctx} =
                build_schema_key(
                  ["schema", original_media_type, "content", "requestBody" | rev_path],
                  jsv_ctx
                )

              {{media_matcher, schema}, jsv_ctx}

            _ ->
              {{media_matcher, :no_validation}, jsv_ctx}
          end
      end)

    {required?, matchers, jsv_ctx}
  end

  defp build_body_validation(nil, _rev_path, jsv_ctx) do
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

  defp build_schema_key(rev_path, jsv_ctx) do
    ref = rev_path_to_ref(rev_path)
    {_schema_key, _jsv_ctx} = JSV.build_key!(jsv_ctx, ref)
  end

  defp rev_path_to_ref(rev_path) do
    Ref.parse!(format_rev_path(rev_path), :root)
  end

  defp format_rev_path(rev_path) do
    path =
      rev_path
      |> :lists.reverse()
      |> Enum.map(&[?/, Ref.escape_json_pointer(to_string(&1))])

    "##{path}"
  end
end
