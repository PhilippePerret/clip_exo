defmodule ClipExoWeb.ExoController do
  use ClipExoWeb, :controller

  use Phoenix.Component # pour to_form, etc.

  alias ClipExo.Exo

  @data_rubriques [
    {"mission", "Mission"},
    {"objectif", "Objectif"},
    {"scenario","Scénario"},
    {"aide", "Aide"},
    {"recommandations","Recommandations"}
  ]

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

  # On arrive dans cette fonction lorsqu'on veut produire un exercice
  # préformaté. Cette fonction présente un formulaire à remplir 
  # autant qu'on veut, pour produire le fichier de l'exercice 
  # préformaté.
  #
  # Dans la nouvelle version, on doit cocher la case "Accepter des
  # données partielle" pour que le fichier se crée avec un minimum
  # de données. Dans le cas contraire, on attendra toutes les données
  # avant de pouvoir construire le fichier.
  #
  def preformated_exo(conn, params) do

    params_exo = params["exo"] || %{}
    
    params_exo
    |> IO.inspect(label: "\nEXO (en entrée)")

    form = params_exo |> to_form(as: "exo")
    render(conn, :data_exo_form, form: form, exo: params_exo, data_rubriques: @data_rubriques)
  end

  @doc """
  Méthode qui produit véritablement l'exercice
  """
  def produce_exo_file(conn, params) do
    exo_params = params["exo"]
    |> IO.inspect(label: "\nEXO (dans produce_exo_preformate)")

    case Exo.data_valid?(exo_params) do
    {:ok, params} ->
      conn = conn
      |> put_flash(:info, "Pour le moment, je ne le fais pas")
      preformated_exo(conn, params)
    {:error, msg_error} ->
      conn = conn
      |> put_flash(:error, msg_error)
      preformated_exo(conn, params)
    end
      # case Exo.build_preformated_exo(params["exo"]) do
      # {:ok, path} -> 
      #   conn
      #   |> put_flash(:info, "Exercice préformé créé avec succès dans #{path}")
      #   |> render(:on_built, exo: exo_params)
      # {:error, error_msg} ->
      #   conn
      #   |> put_flash(:error, error_msg)
      #   |> preformated_exo(params)
      # end
  end
end
