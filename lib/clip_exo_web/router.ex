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

    get "/manuel", PageController, :manuel
    get "/fabrication", PageController, :fabrication
    get "/formatage", PageController, :aide_formatage
    get "/exercice/:folder/:file", PageController, :serve_file
    get "/", PageController, :home
  end


  scope "/exo", ClipExoWeb do
    pipe_through :browser

    post "/edit", ExoController, :editor
    get "/edit", ExoController, :editor
    get "/produire", ExoController, :produire
    get "/preformater", ExoController, :preformated_exo
    post "/preformate", ExoController, :produce_exo_preformate
    get "/preformate", ExoController, :preformated_exo
    post "/build", ExoController, :build
    get  "/build", ExoController, :build
  end

  # Other scopes may use custom stacks.
  # scope "/api", ClipExoWeb do
  #   pipe_through :api
  # end
end
