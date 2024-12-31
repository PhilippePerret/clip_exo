defmodule ClipExoWeb.ExoController do
  use ClipExoWeb, :controller

  use Phoenix.Component # pour to_form, etc.

  alias ClipExo.Exo

  @data_rubriques Exo.get_data_rubriques
  @data_niveaux   Exo.get_data_niveaux

  # def produire(conn, _params) do
  #   render(conn, :produire, ui: ClipExo.ui_terms() )
  # end

  # Construction des trois fichiers finaux de l'exercice, le fichier
  # participant, le fichier formateur et le fichier caractéristiques.
  # def build(conn, params) do
  def produire(conn, params) do
    options = %{
      open_folder: params["open_folder"]
    }
    case Exo.build(params["exo"], options) do
    {:ok, exo} ->
      render(conn, :builder, exo: exo)
    {:error, err_msg} ->
      conn |> put_flash(:error, err_msg)
      render(conn, :on_error, error: err_msg)
    end
  end

  # Édition de l'exercice
  def editer(conn, params) do
    case params["exo"] do
    nil -> on_error_miss_exo(conn)
    ""  -> on_error_miss_exo(conn)
    exo ->
      exo = Map.put(exo, "contenu", Exo.get_content_of(params["exo"]["path"]))
      Exo.memo_last_traitement(exo)
      render(conn, :editor, exo: exo, ui: ClipExo.ui_terms)
    end
  end

  defp on_error_miss_exo(conn) do
    render(conn, :on_error, error: "Il faut choisir l'exercice.")
  end

  # Sauvegarde du code de l'exercice (fichier de base)
  def save(conn, params) do
    exo = params["exo"]
    conn =
      case Exo.save(exo) do
      :ok -> 
        conn |> put_flash(:info, "Fichier enregistré.")
      {:error, erreur} ->
        conn |> put_flash(:error, erreur)
      end
    render(conn, :editor, exo: exo, ui: ClipExo.ui_terms)
  end

  @doc """
  Pour ouvrir le fichier dans le Finder
  """
  def ouvrir(conn, params) do
    conn = conn |> put_flash(:info, "L'exercice est ouvert sur le bureau.")
    Exo.open(Exo.get_from_params(params))
    origin  = Enum.at(Plug.Conn.get_req_header(conn, "origin"), 0)
    referer = Enum.at(Plug.Conn.get_req_header(conn, "referer"), 0)
    referer = String.replace(referer, origin, "")
    redirect(conn, to: referer, params: params)
  end

  # Depuis la page "imprimer", on peut ouvrir les fichiers dans 
  # Google Chrome dans la perspective de les imprimer.
  def imprimer(conn, %{"open" => _open} = params) do
    exo = Exo.get_from_params(params)
    conn =
      case Exo.open_in_chrome(exo) do
      {:ok, msg} -> conn |> put_flash(:info, msg)
      {:error, erreur} -> conn |> put_flash(:error, "Impossible d'ouvrir le fichier dans chrome : #{erreur}…")
      end
    imprimer(conn, Map.delete(params, "open"))
  end

  # Arrivée "normal" sur la page "Imprimer". Un bouton permettra
  # d'ouvrir les fichiers de l'exercice.
  # Cette page donne des indications sur la façon d'imprimer les
  # exercices ou de produire leur PDF.
  def imprimer(conn, params) do
    _exo = Exo.get_from_params(params)
    render(conn, :imprimer, exo: params["exo"])
  end


  # On arrive dans cette fonction lorsqu'on veut produire un exercice
  # préformaté. Cette fonction présente un formulaire à remplir 
  # autant qu'on veut, pour produire le fichier de l'exercice 
  # préformaté.
  #
  # Dans la nouvelle version, on doit cocher la case "Accepter des
  # données partielles" pour que le fichier se crée avec un minimum
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
