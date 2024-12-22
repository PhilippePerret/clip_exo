defmodule ClipExoWeb.ExoController do
  use ClipExoWeb, :controller

  use Phoenix.Component # pour to_form, etc.

  alias ClipExo.{Exo, ExoSchema}

  def build(conn, params) do
    IO.inspect(params, label: "\nparams")
    Exo.build(params["exo"])
    render(conn, :builder, exo: params["exo"])
  end

  def preformated_exo(conn, params) do
    IO.inspect(params, label: "\nPARAMS")
    
    exo_params = 
      params["exo"]
      |> IO.inspect(label: "\nEXO (en entrée)")
      |> formate_param_rubriques()
      |> IO.inspect(label: "\nEXO (à la fin)")

    exo = %Exo{}
    exo_schema = %ClipExo.ExoSchema{
      titre: exo.infos.titre,
      auteur: exo.infos.auteur,
      created_at: exo.infos.created_at,
      body: exo.body
    }
    form = 
      exo_schema
      |> ExoSchema.changeset(params["exo"] || %{})
      |> to_form(as: "exo")
    render(conn, :preformated, exo: exo_params, form: form)
  end

  defp formate_param_rubriques(params) do
    if params["rubriques"] do
      rubriques_ser = 
        params["rubriques"]
        |> Enum.reduce(%{}, fn x, acc ->
            Map.put(acc, "rubriques[#{x}]", "on") 
          end)
        |> IO.inspect(label: "\nrubriques séréalisées")
      params = Map.delete(params, "rubriques")
      Map.merge(params, rubriques_ser)
      |> IO.inspect(label: "\nPARAMS à la fin de formate_param_rubriques")
    else
      params
    end
  end

  @doc """
  Méthode qui produit véritablement l'exercice
  """
  def produce_preformated_exo(conn, params) do
    IO.inspect(params["exo"], label: "\nEXO (dans produce)")
    exo_params = 
      params["exo"]
      |> formate_param_rubriques()
    case Exo.build_preformated_exo(params["exo"]) do
    {:ok, _} -> 
      conn
      |> put_flash(:info, "Exercice préformé créé avec succès dans ...")
      |> render(:on_build, exo: exo_params)
    {:error, error_msg} ->
      conn
      |> put_flash(:error, error_msg)
      |> redirect(to: ~p"/exo/preformated?#{URI.encode_query(exo_params)}")
    end
  end
end
