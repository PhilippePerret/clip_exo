defmodule ClipExoWeb.ExoController do
  use ClipExoWeb, :controller

  alias ClipExo.Exo

  def build(conn, params) do
    IO.inspect(params, label: "\nparams")
    Exo.build(params["exo"])
    render(conn, :builder, exo: params["exo"])
  end
end
