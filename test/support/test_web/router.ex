defmodule Moonwalk.TestWeb.Router do
  use Phoenix.Router

  pipeline :api_from_paths do
    plug Moonwalk.Plugs.SpecProvider, spec: Moonwalk.TestWeb.PathsApiSpec
  end

  pipeline :api_from_doc do
    plug Moonwalk.Plugs.SpecProvider, spec: Moonwalk.TestWeb.DeclarativeApiSpec
  end

  scope "/generated" do
    pipe_through :api_from_paths

    scope "/meta", Moonwalk.TestWeb do
      get "/before-metas", MetaController, :before_metas
      get "/after-metas", MetaController, :after_metas
      get "/overrides-param", MetaController, :overrides_param
    end

    scope "/body", Moonwalk.TestWeb do
      post "/inline-single", BodyController, :inline_single
      post "/module-single", BodyController, :module_single
      post "/module-single-no-required", BodyController, :module_single_not_required
      post "/form", BodyController, :handle_form
      post "/undefined-operation", BodyController, :undefined_operation
      post "/ignored-action", BodyController, :ignored_action
      post "/wildcard", BodyController, :wildcard_media_type
      post "/boolean-schema-false", BodyController, :boolean_schema_false

      # Manual tests
      post "/manual-form-handle", BodyController, :manual_form_handle
      get "/manual-form-show", BodyController, :manual_form_show
    end

    scope "/params/:slug", Moonwalk.TestWeb do
      get "/t/:theme", ParamController, :single_path_param
      get "/t/:theme/c/:color", ParamController, :two_path_params
      get "/generic", ParamController, :generic_param_types
      get "/arrays", ParamController, :array_types
      get "/boolean-schema-false", ParamController, :boolean_schema_false

      scope "/s/:shape" do
        get "/", ParamController, :scope_only
        get "/t/:theme", ParamController, :scope_and_single
        get "/t/:theme/c/:color", ParamController, :scope_and_two_path_params
      end
    end

    scope "/resp", Moonwalk.TestWeb do
      get "/fortune-200-valid", ResponseController, :fortune_200_valid
      get "/fortune-200-invalid", ResponseController, :fortune_200_invalid
      get "/fortune-200-no-content-def", ResponseController, :fortune_200_no_content_def
      get "/fortune-200-bad-content-type", ResponseController, :fortune_200_bad_content_type
      get "/fortune-200-no-operation", ResponseController, :fortune_200_no_operation
    end

    scope "/method", Moonwalk.TestWeb do
      get "/p", MethodController, :single_fun
      post "/p", MethodController, :single_fun
      put "/p", MethodController, :single_fun
      patch "/p", MethodController, :single_fun
      delete "/p", MethodController, :single_fun
      options "/p", MethodController, :single_fun
      trace("/p", MethodController, :single_fun)
      head "/p", MethodController, :single_fun
    end
  end

  scope "/provided" do
    pipe_through :api_from_doc
    post "/potions", Moonwalk.TestWeb.LabController, :create_potion
    get "/:lab/alchemists", Moonwalk.TestWeb.LabController, :list_alchemists
    post "/:lab/alchemists", Moonwalk.TestWeb.LabController, :search_alchemists
  end

  match :*, "/*path", Moonwalk.TestWeb.Router.Catchall, :not_found, warn_on_verify: true
end

defmodule Moonwalk.TestWeb.Router.Catchall do
  use Phoenix.Controller,
    formats: [:html, :json],
    layouts: []

  @spec not_found(term, term) :: no_return()
  def not_found(conn, _) do
    send_resp(conn, 404, "Not Found (catchall)")
  end
end
