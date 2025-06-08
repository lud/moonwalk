defmodule Moonwalk.TestWeb.BodyController do
  alias JSV.Schema
  alias Moonwalk.TestWeb.Responder
  use Moonwalk.TestWeb, :controller

  plug Moonwalk.Plugs.ValidateRequest

  @plant_schema %{
    type: :object,
    title: "InlinePlantSchema",
    properties: %{
      name: Schema.non_empty_string(),
      sunlight:
        Schema.string_to_atom_enum([:full_sun, :partial_sun, :bright_indirect, :darnkness])
    },
    required: [:name, :sunlight]
  }

  # pass the schema directly as the value of request_body
  operation :inline_single,
    request_body: @plant_schema

  def inline_single(conn, params) do
    Responder.reply(conn, params)
  end

  defmodule SoilSchema do
    require(JSV).defschema(%{
      type: :object,
      properties: %{
        acid: Schema.boolean(),
        density: Schema.number()
      },
      required: [:acid, :density]
    })
  end

  defmodule PlantSchema do
    require(JSV).defschema(%{
      type: :object,
      properties: %{
        name: Schema.non_empty_string(),
        sunlight:
          Schema.string_to_atom_enum([:full_sun, :partial_sun, :bright_indirect, :darnkness]),
        soil: SoilSchema
      },
      required: [:name, :sunlight]
    })
  end

  operation :module_single,
    operation_id: :custom_operation_id_module_single,
    request_body: {PlantSchema, []}

  def module_single(conn, params) do
    Responder.reply(conn, params)
  end

  operation :handle_form,
    request_body: [content: %{"application/x-www-form-urlencoded" => %{schema: PlantSchema}}]

  def handle_form(conn, params) do
    Responder.reply(conn, params)
  end

  def undefined_operation(conn, params) do
    Responder.reply(conn, params)
  end

  operation :ignored_action, false

  def ignored_action(conn, params) do
    Responder.reply(conn, params)
  end

  operation :wildcard_media_type,
    request_body: [
      content: %{
        "*/*" => %{schema: false},
        "application/json" => %{schema: PlantSchema}
      }
    ]

  def wildcard_media_type(conn, params) do
    Responder.reply(conn, params)
  end
end
