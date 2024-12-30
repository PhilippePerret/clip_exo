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
    get "/forgerie", PageController, :forgerie
    get "/formatage", PageController, :aide_formatage
    get "/exercice/:folder/:file", PageController, :serve_file
    get "/", PageController, :home
  end


  scope "/exo", ClipExoWeb do
    pipe_through :browser
    
    post "/save",   ExoController, :save
    get  "/save",  ExoController, :editer # !
    post "/editer", ExoController, :editer
    get "/editer", ExoController, :editer
    get "/preformater", ExoController, :preformated_exo
    post "/produce_data_file", ExoController, :produce_exo_file
    get "/produce_data_file", ExoController, :produce_exo_file
    get "/preformate", ExoController, :preformated_exo
    get "/produire", ExoController, :produire
    post "/produire", ExoController, :produire
  end
  
  scope "/:anyway", ClipExoWeb do
    pipe_through :browser

    get "/", PageController, :cul_de_sac
    post "/", PageController, :cul_de_sac

  end

end
