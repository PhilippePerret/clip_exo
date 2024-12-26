defmodule ClipExoWeb.PageController do
  use ClipExoWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
  
  def serve_file(conn, %{"folder" => folder, "file" => file}) do
    path = Path.join(["_exercices/html", folder, file])
    case File.read(path) do
    {:ok, content} ->
      send_resp(conn, 200, content)
    {:error, err_msg} ->
      send_resp(conn, 404, err_msg)
    end
  end

end
