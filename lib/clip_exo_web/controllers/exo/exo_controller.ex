defmodule ClipExoWeb.ExoController do
  use ClipExoWeb, :controller

  def build(conn, params) do
    IO.inspect(params, label: "\nparams")
    render(conn, :builder, exo: params["exo"])
  end
end
