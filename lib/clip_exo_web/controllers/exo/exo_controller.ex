defmodule ClipExoWeb.ExoController do
  use ClipExoWeb, :controller

  use Phoenix.Component # pour to_form, etc.

  alias ClipExo.{Exo, ExoSchema}

  def produire(conn, _params) do
    render(conn, :produire, ui: ClipExo.ui_terms() )
  end

  def build(conn, params) do
    options = %{
      open_folder: params["open_folder"]
    }
    case Exo.build(params["exo"], options) do
    {:ok, exo} ->
      render(conn, :builder, exo: exo)
    {:error, err_msg} ->
      conn |> put_flash(:error, err_msg)
      render(conn, :no_way, error: err_msg)
    end
  end

  def editor(conn, params) do
    params = Map.merge(%{"exo" => %{
      "path" => params["p"], # première arrivée
    }}, params)
    exo = %{
      "path" => params["exo"]["path"],
      "contenu" => Exo.get_content_of(params["exo"]["path"])
    }
    render(conn, :editor, exo: exo)
  end

  def preformated_exo(conn, params) do
    IO.inspect(params, label: "\nPARAMS")
    
    exo_params = 
      params["exo"]
      |> IO.inspect(label: "\nEXO (en entrée)")
      # |> formate_param_rubriques()
      # |> IO.inspect(label: "\nEXO (à la fin)")

    exo = %Exo{}
    exo_schema = %ClipExo.ExoSchema{
      titre: exo_params["titre"] || exo.infos.titre,
      reference: exo_params["reference"] || exo.infos.reference,
      auteur: exo_params["auteur"] || exo.infos.auteur,
      created_at: exo.infos.created_at,
      body: exo.body,
      rubrique_mission: exo_params["rubrique_mission"],
      rubrique_objectif: exo_params["rubrique_objectif"],
      rubrique_scenario: exo_params["rubrique_scenario"],
      rubrique_recommandations: exo_params["rubrique_recommandations"],
      rubrique_aide: exo_params["rubrique_aide"]
    }
    form = 
      exo_schema
      |> ExoSchema.changeset(params["exo"] || %{})
      |> to_form(as: "exo")
    render(conn, :preformated, form: form)
  end

  @doc """
  Méthode qui produit véritablement l'exercice
  """
  def produce_preformated_exo(conn, params) do
    IO.inspect(params["exo"], label: "\nEXO (dans produce)")
    exo_params = params["exo"]
    case Exo.build_preformated_exo(params["exo"]) do
    {:ok, path} -> 
      conn
      |> put_flash(:info, "Exercice préformé créé avec succès dans #{path}")
      |> render(:on_built, exo: exo_params)
    {:error, error_msg} ->
      conn
      |> put_flash(:error, error_msg)
      |> preformated_exo(params)
    end
  end
end
