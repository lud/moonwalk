defmodule Moonwalk.TestWeb.MetaController do
  use Moonwalk.TestWeb, :controller

  operation :before_metas,
    operation_id: "meta_before",
    responses: dummy_responses()

  def before_metas(_conn, _) do
    raise "not called"
  end

  tags ["shared1", "zzz"]
  parameter :shared1, in: :query

  # TODO(doc) macros can be called multiple times and are cumulative
  tags ["shared2", "zzz"]
  parameter :shared2, in: :query

  operation :after_metas,
    operation_id: "meta_after",
    tags: ["zzz", "aaa"],
    parameters: [
      self1: [in: :query],
      self2: [in: :query]
    ],
    responses: dummy_responses()

  def after_metas(_conn, _) do
    raise "not called"
  end

  operation :overrides_param,
    operation_id: "meta_override",
    tags: [],
    parameters: [
      shared2: [in: :query, schema: %{"overriden" => true}],
      # not an override as we are defining this one in path
      shared1: [in: :path]
    ],
    responses: dummy_responses()

  def overrides_param(_conn, _) do
    raise "not called"
  end
end
