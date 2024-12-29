defmodule ClipExoWeb.ExoController do
  use ClipExoWeb, :controller

  use Phoenix.Component # pour to_form, etc.

  alias ClipExo.Exo

  @data_rubriques Exo.get_data_rubriques
  @data_niveaux   Exo.get_data_niveaux

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

  def editer(conn, params) do
    exo = params["exo"] || %{}
    exo = Map.put(exo, "contenu", Exo.get_content_of(params["exo"]["path"]))
    render(conn, :editor, exo: exo)
  end

  def save(conn, params) do
    exo = params["exo"]
    conn =
      case Exo.save(exo) do
      :ok -> 
        conn |> put_flash(:info, "Fichier enregistré.")
      {:error, erreur} ->
        conn |> put_flash(:error, erreur)
      end
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

    params_exo = 
    if (not is_nil((System.get_env("USER_prenom")))) and (is_nil(params_exo["auteur"]) or params_exo["auteur"] == "") do
      Map.put(params_exo, "auteur", "#{System.get_env("USER_prenom")} #{System.get_env("USER_nom")}")
    else params_exo end

    params_exo = Map.put(params_exo, "rubriques", params_exo["rubriques"] || [])

    
    params_exo
    |> IO.inspect(label: "\nEXO (en entrée)")

    form = params_exo |> to_form(as: "exo")
    render(conn, :data_exo_form, %{
      form:           form, 
      exo:            params_exo, 
      data_rubriques: @data_rubriques,
      data_niveaux:   @data_niveaux
    })
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
      |> put_flash(:info, "Informations correctes. Construction du fichier des données de l'exercice.")
      build_preformated_exo(conn, params)
    {:error, msg_error} ->
      conn = conn
      |> put_flash(:error, msg_error)
      preformated_exo(conn, params)
    end
  end

  defp build_preformated_exo(conn, params) do
    case Exo.build_preformated_exo(params) do
    {:ok, params} ->
      # Si la construction a réussi, on passe tout de suite à l'édition du fichier
      editer(conn, %{"exo" => %{"path" => params["path"]}})
    {:error, msg_error} ->
      conn = conn
      |> put_flash(:error, msg_error)
      preformated_exo(conn, params)
    end
  end

end
