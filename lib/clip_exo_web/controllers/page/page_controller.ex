defmodule ClipExoWeb.PageController do
  use ClipExoWeb, :controller

  alias ExoInnerFormater
  alias ClipExo.Exo
  
  def home(conn, _params) do
    render(conn, :home)
  end

  def forgerie(conn, params) do
    exo = Map.put(params, "path", get_path_from_params_or_last_traitement(params))

    render(conn, :forgerie, ui: ClipExo.ui_terms, exo: exo, exo_liste: Exo.liste_exercices())
  end

  def get_path_from_params_or_last_traitement(params) do
    if params["exo"] && params["exo"]["path"] do
      params["exo"]["path"]
    else
      Last.get(:path)
    end
  end

  def manuel(conn, _params) do
    render(conn, :manuel, ui: ClipExo.ui_terms)
  end
  
  # Pour afficher les fichiers dans des iframes
  def serve_file(conn, %{"folder" => folder, "file" => file}) do
    path = Path.join(["_exercices/html", folder, file])
    case File.read(path) do
    {:ok, content} ->
      send_resp(conn, 200, content)
    {:error, err_msg} ->
      send_resp(conn, 200, "<div class=\"warning\">#{err_msg}</div>")
    end
  end

  def aide_formatage(conn, _params) do
    render(conn, :aide_formatage, %{
      liste_classes_paragraphe: ExoInnerFormater.get_paragraph_styles()
    })
  end


  def cul_de_sac(conn, %{"anyway" => anyway}) do
    render(conn, :cul_de_sac, anyway: anyway)
  end
end
