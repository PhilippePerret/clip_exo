defmodule ClipExoWeb.ExoController do
  use ClipExoWeb, :controller

  alias ClipExo.Exo

  def build(conn, params) do
    IO.inspect(params, label: "\nparams")
    Exo.build(params["exo"])
    render(conn, :builder, exo: params["exo"])
  end

  def preformated_exo(conn, params) do
    IO.inspect(params["exo"], label: "\nEXO")
    render(conn, :preformated, exo: params["exo"])
  end
end
