defmodule ClipExoWeb.Router do
  use ClipExoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ClipExoWeb.Layouts, :root}
    # plug :protect_from_forgery
    # plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ClipExoWeb do
    pipe_through :browser

    get "/", PageController, :home
  end


  scope "/exo", ClipExoWeb do
    pipe_through :browser

    get "/preformated", ExoController, :preformated_exo
    post "/preformate", ExoController, :preformated_exo
    get "/preformate", ExoController, :preformated_exo
    post "/build", ExoController, :build
    get  "/build", ExoController, :build
  end

  # Other scopes may use custom stacks.
  # scope "/api", ClipExoWeb do
  #   pipe_through :api
  # end
end
