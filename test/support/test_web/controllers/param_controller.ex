defmodule Moonwalk.TestWeb.ParamController do
  alias JSV.Schema
  alias Moonwalk.TestWeb.Responder
  use Moonwalk.TestWeb, :controller

  plug Moonwalk.Plugs.ValidateRequest

  @shape Schema.string_to_atom_enum([:square, :circle])
  @theme Schema.string_to_atom_enum([:dark, :light])
  @color Schema.string_to_atom_enum([:red, :blue])
  @query_int Schema.integer(minimum: 10, maximum: 100)

  operation :generic_param_types,
    parameters: [
      string_param: [in: :query, schema: Schema.string()],
      boolean_param: [in: :query, schema: Schema.boolean()],
      integer_param: [in: :query, schema: Schema.integer()],
      number_param: [in: :query, schema: Schema.number()]
    ]

  def generic_param_types(conn, params) do
    Responder.reply(conn, params)
  end

  operation :array_types,
    parameters: [
      numbers: [in: :query, schema: Schema.array_of(Schema.integer())],
      names: [in: :query, schema: Schema.array_of(Schema.string())]
    ]

  def array_types(conn, params) do
    Responder.reply(conn, params)
  end

  operation :single_path_param,
    parameters: [
      theme: [in: :path, schema: @theme]
    ]

  def single_path_param(conn, params) do
    Responder.reply(conn, params)
  end

  operation :two_path_params,
    parameters: [
      theme: [in: :path, schema: @theme],
      color: [in: :path, schema: @color]
    ]

  def two_path_params(conn, params) do
    Responder.reply(conn, params)
  end

  operation :scope_only,
    parameters: [
      shape: [in: :path, schema: @shape]
    ]

  def scope_only(conn, params) do
    Responder.reply(conn, params)
  end

  operation :scope_and_single,
    parameters: [
      shape: [in: :path, schema: @shape],
      theme: [in: :path, schema: @theme]
    ]

  def scope_and_single(conn, params) do
    Responder.reply(conn, params)
  end

  operation :scope_and_two_path_params,
    parameters: [
      shape: [in: :path, schema: @shape],
      theme: [in: :path, schema: @theme],
      color: [in: :path, schema: @color],
      shape: [in: :query, schema: @query_int, required: true],
      theme: [in: :query, schema: @query_int],
      # That last param uses a self ref and it should work
      color: [
        in: :query,
        schema: %{
          "$id" => "test://test",
          "d" => %{"shape" => @query_int},
          "$ref" => "test://test#/d/shape"
        }
      ]
    ]

  def scope_and_two_path_params(conn, params) do
    Responder.reply(conn, params)
  end
end
