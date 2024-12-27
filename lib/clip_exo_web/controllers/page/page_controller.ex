defmodule ClipExoWeb.PageController do
  use ClipExoWeb, :controller

  alias ExoInnerFormater
  
  def home(conn, _params) do
    render(conn, :home)
  end
  
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
    # Pour être toujours à la page, on fait une copie du fichier 
    # clip_exo.css dans le dossier /priv/static/css
    File.cp!("./_exercices/css/clip_exo.css", "./priv/static/css/clip_exo.css")
    render(conn, :aide_formatage, %{
      liste_classes_paragraphe: ExoInnerFormater.get_paragraph_styles()
    })
  end

end
