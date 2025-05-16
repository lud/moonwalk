defmodule Moonwalk.TestWeb.ParamController do
  alias JSV.Schema
  alias Moonwalk.TestWeb.Responder
  use Moonwalk.TestWeb, :controller

  plug Moonwalk.Plug.ValidateRequest

  @shape Schema.string_to_atom_enum([:square, :circle])
  @theme Schema.string_to_atom_enum([:dark, :light])
  @color Schema.string_to_atom_enum([:red, :blue])
  @query_int Schema.integer(minimum: 10, maximum: 100)

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
      color: [in: :query, schema: @query_int]
    ]

  def scope_and_two_path_params(conn, params) do
    Responder.reply(conn, params)
  end
end
