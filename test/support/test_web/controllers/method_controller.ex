defmodule Moonwalk.TestWeb.MethodController do
  alias Moonwalk.TestWeb.Responder
  use Moonwalk.TestWeb, :controller

  defmodule RespSchema do
    require(JSV).defschema(%{
      type: :object,
      properties: %{op_id: %{type: :string}},
      required: [:op_id]
    })
  end

  response = RespSchema

  operation :single_fun, operation_id: "mGET", responses: [ok: response], method: :get
  operation :single_fun, operation_id: "mPOST", responses: [ok: response], method: :post
  operation :single_fun, operation_id: "mPUT", responses: [ok: response], method: :put
  operation :single_fun, operation_id: "mDELETE", responses: [ok: response], method: :delete
  operation :single_fun, operation_id: "mOPTIONS", responses: [ok: response], method: :options
  operation :single_fun, operation_id: "mHEAD", responses: [ok: response], method: :head
  operation :single_fun, operation_id: "mPATCH", responses: [ok: response], method: :patch
  operation :single_fun, operation_id: "mTRACE", responses: [ok: response], method: :trace

  def single_fun(conn, params) do
    Responder.reply(conn, params)
  end
end
