defmodule ClipExoWeb.PageController do
  use ClipExoWeb, :controller

  alias ExoInnerFormater
  
  def home(conn, _params) do
    render(conn, :home)
  end

  def fabrication(conn, _params) do
    render(conn, :fabrication, ui: ClipExo.ui_terms)
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

end
