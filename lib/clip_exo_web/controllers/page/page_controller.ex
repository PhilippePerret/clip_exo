defmodule ClipExoWeb.PageController do
  use ClipExoWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end


end
