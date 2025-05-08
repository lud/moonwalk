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
