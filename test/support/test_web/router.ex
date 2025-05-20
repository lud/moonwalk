defmodule Moonwalk.TestWeb.Router do
  use Phoenix.Router

  scope "/meta", Moonwalk.TestWeb do
    get "/hello", MetaController, :hello
  end

  scope "/body", Moonwalk.TestWeb do
    post "/inline-single", BodyController, :inline_single
    post "/module-single", BodyController, :module_single
    post "/form", BodyController, :handle_form
    post "/undefined-operation", BodyController, :undefined_operation
    post "/ignored-action", BodyController, :ignored_action
    post "/wildcard", BodyController, :wildcard_media_type
  end

  scope "/params", Moonwalk.TestWeb do
    get "/t/:theme", ParamController, :single_path_param
    get "/t/:theme/c/:color", ParamController, :two_path_params
    get "/generic", ParamController, :generic_param_types
    get "/arrays", ParamController, :array_types
  end

  scope "/params/s/:shape", Moonwalk.TestWeb do
    get "/", ParamController, :scope_only
    get "/t/:theme", ParamController, :scope_and_single
    get "/t/:theme/c/:color", ParamController, :scope_and_two_path_params
  end

  match :*, "/*path", Moonwalk.TestWeb.Router.Catchall, :not_found
end

defmodule Moonwalk.TestWeb.Router.Catchall do
  use Moonwalk.TestWeb, :controller

  @spec not_found(term, term) :: no_return()
  def not_found(conn, _) do
    raise """
    unmatched route

    #{conn.method} #{Enum.map(conn.path_info, &["/", &1])}
    """
  end
end
