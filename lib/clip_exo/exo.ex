# Méthodes propres à un exercice
defmodule ClipExo.Exo do

  defstruct [
    infos: %{
      name: "",
      path:  "",
      folder: "",
      reference: "",
      titre: "",
      auteur: "",
      created_at: Date.utc_today(),
      logiciels: "",
      revisions: [],
      competences: [],
      niveau: "",
      duree: "",
      css_files: nil
    },
    body:       "contenu brut de l'exercice",
    body_html:  nil,  # le contenu formaté
    rubriques:  [],   # pour les rubriques des infos
    suivi: nil        # Pour le suivi de la construction
  ]

  alias ClipExo.ExoBuilder, as: Builder

  @folder "./_exercices/clipexo/"
  @html_folder "./_exercices/html"

  @doc """
  Retourne le contenu de l'exercice clip.exo +path+

  +path+ est une path vérifiée
  """
  def get_content_of(path) do
    File.read!(path)
  end

  @doc """
  @main

  Construction de l'exercice définit dans +exo+ (%ClipExo.Exo)
  Function principale appelée par le bouton pour construire l'exercice

  Pour le moment, +exo+ ne contient que "file_path", le chemin
  d'accès relatif au fichier. Par défaut, on le cherche dans @folfder
  """
  def build(params_exo) do
    with  {:ok, path} <- get_path_exo(params_exo),
          {:ok, exo}  <- parse_whole_file(path),
          {:ok, exo}  <- build_two_files(exo),
          {:ok, exo}  <- copy_required_files(exo),
          {:ok, exo}  <- open_exo_html_folder(exo) do
            {:ok, exo}
    else
      {:error, message_erreur} ->
        {:error, message_erreur}
    end
  end

  def copy_required_files(exo) do
    Builder.copy_required_files(exo)
    # => {:ok, exo} ou {:error, erreur}
  end

  def parse_whole_file(path) do
    IO.puts "--> parse_whole_file"
    case parse_whole_file_code(File.read!(path)) do
    {:ok, exo} ->
      exo_infos = exo.infos
      exo_infos =
        if is_nil(exo_infos.name) do
          %{exo_infos | name: get_name_from_path(path)}
        else
          exo_infos
        end
      exo_infos = Map.merge(exo_infos, %{
        file_name: Path.basename(path),
        path: path,
        folder: Path.dirname(path),
        htm_folder: Path.join([@html_folder, exo.infos.name])
      })
      exo = %{exo | infos: exo_infos}
      IO.puts "<-- parse_whole_file"
      {:ok, exo}
    {:error, msg} -> 
      {:error, msg}
    end
  end

  # Retourne le nom de l'exercice tiré de +path+
  # Note : On ne le cherche que s'il n'est pas défini dans
  #        le fichier.
  defp get_name_from_path(path) do
    Path.basename(path)
    |> String.split(".")
    |> Enum.at(0)
  end

  @doc """
  Demande de construction des deux fichiers de l'exercice .clip.exo
  """
  def build_two_files(%ClipExo.Exo{} = exo) do
    IO.puts "--> build_two_files"
    suivi = exo.suivi || ["Début de la construction"]

    suivi = suivi ++ [case Builder.build_file_specs(exo) do
      {:ok, _exo} -> "👍 Construction du fichier des caractéristiques"
      {:error, msg} -> "💣 Échec de la construction du fichier des caractéristiques : " <> msg
    end]

    suivi = suivi ++ [case Builder.build_file_exo(exo) do
      {:ok, _exo} -> "👍 Construction du fichier de l'exercice"
      {:error, msg} -> "💣 Échec de la construction du fichier de l'exercice : " <> msg
    end]

    exo = %{exo | suivi: suivi}

    IO.puts "<-- build_two_files"
    {:ok, exo}
  end

  ###################################################################

  @doc """
  Méthode qui prend le code +code+, en supposant qu'il est
  au format clip.exo et le transforme en table (liste) façon
  AST pour produire le document HTML.
  """
  def parse_whole_file_code(code) do
    code
    |> decompose_header_and_body()
  end

  @reg_front_matter ~r/(^|\n)---\n(?<front_matter>(?:.|\n)*)\n---\n(?<body>(.|\n)*)\z/Um
  defp decompose_header_and_body(code) do
    if Regex.match?(@reg_front_matter, code) do

      # On découpe le code brut du fichier (en front-matter et body)
      resultat = Regex.named_captures(@reg_front_matter, code)

      # On récupère les informations du front-matter
      infos = get_infos_from_front_matter(resultat["front_matter"])
      |> IO.inspect(label: "\nINFOS de front-matter")
      
      # On prend le body du résultat
      body  = resultat["body"]
      
      ok = (elem(infos, 0) == :ok && body != "") && :ok || :error
      
      # Tout est OK, on peut merger les informations
      infos = Map.merge(%ClipExo.Exo{}.infos, elem(infos, 1))
      
      # --- Instanciation de Exo ---
      exo = %ClipExo.Exo{infos: infos, body: body}
      {ok, exo}
    else
      {:error, "Le fichier est mal formaté {TODO: Lien d'aide}"}
    end
  end

  @reg_front_matter_line ~r/^(?<property>.*)[\:\=](?<value>.*)$/
  defp get_infos_from_front_matter(front_matter) do
    infos =
      String.split(front_matter, "\n")
      |> Enum.map(fn line ->
        case Regex.named_captures(@reg_front_matter_line, line) do
        nil -> {:error, "Mauvaise ligne d'info : #{line}"}
        captures ->
          {
            captures["property"] |> String.trim() |> String.downcase() |> String.to_atom(),
            captures["value"] |> String.trim() |> transform_value_by_property(captures["property"])
          }
        end
        end)
      |> Enum.reject(fn x -> elem(x,0) == :"" || elem(x,1) == "" end)
      |> Enum.reduce(%{}, fn tup, acc ->
          Map.put(acc, elem(tup, 0), elem(tup, 1))
        end)
    {:ok, infos}
  end

  # Transformation de certains valeurs du front-matter (principale-
  # ment de string vers liste)
  defp transform_value_by_property(value, property) do
    case property do
    "css_files"     -> StringTo.list(value)
    "competences"   -> StringTo.list(value)
    "logiciels"     -> StringTo.list(value)
    "revisions"     -> StringTo.list(value)
      _ -> value
    end
  end


  @doc """
  Ouvre le dossier html de l'exercice dans le finder
  """
  def open_exo_html_folder(exo) do
    System.shell("open \"#{Path.expand(Builder.exo_html_folder(exo))}\"")
    {:ok, exo}
  end

  defp build_path_from(nil), do: nil
  defp build_path_from(path) do
    path_init = path
    path = add_extensions_if_needed(path)
    path_with_folder = Path.join([@folder, path])
    cond do
    File.exists?(path) -> {:ok, path}
    File.exists?(path_with_folder) -> {:ok, path_with_folder}
    true -> {:error, "Impossible de trouver le path du fichier à partir de #{path_init}"}
    end
  end

  # Pour définir précisément le chemin d'accès au fichier de l'exercice, qui n'existe
  # pas forcément encore
  defp get_path_exo(params_exo) do
    if params_exo["file_path"] do
      { :ok, Path.join([@folder, add_extensions_if_needed(params_exo["file_path"])]) }
    else
      { :error, "Il faut définir au moins le nom du fichier."}
    end
  end

  # Retourne le chemin d'accès au fichier désigné par +path+, qui doit
  # exister
  def get_path_of_exo(path) do
    case build_path_from(path) do
    {:ok, path}       -> path
    {:error, err_msg} -> {:error, err_msg}
    nil -> {:error, "Il faut fournir le chemin de référence de l’exercice."}
    end
  end

  # Ajoute si nécessaire ".clip.exo" ou simplement ".exo" au nom du fichier fourni
  # dans +path+ (qui peut être un simple nom de fichier ou un path complet)
  defp add_extensions_if_needed(path) do
    if Regex.match?(~r/\./, path) do
      paths = String.split(path, ".")
      exts  = [Enum.fetch!(paths, -2), Enum.fetch!(paths, -1)]
      |> IO.inspect(label: "\nexts")
      case exts do
        ["clip", "exo"] -> path
        [_, "clip"]       -> path <> ".exo"
        _ -> path <> ".clip.exo"
      end
    else
      path <> ".clip.exo"
    end
  end


  @doc """
  Construction de l'exercice préformaté
  """
  def build_preformated_exo(params) do
    params
    |> IO.inspect(label: "\nPARAMS pour la construction")
    exo_name = params["path"]
    exo_path = Path.join([@folder, add_extensions_if_needed(exo_name)])
    cond do
    exo_path == ".clip.exo" ->
      {:error, "Il faut fournir le nom du fichier"}
    File.exists?(exo_path) ->
      {:error, "Un fichier d’exercice porte déjà le nom #{exo_name}\n(#{exo_path})"}
    true ->
      # On peut créer le fichier exercice
      File.write!(exo_path, modele_preformated(params), [:utf8])
      {:ok, exo_path}
    end
  end

  def modele_preformated(params) do
    IO.inspect(params, label: "\nParams in modele_preformated")
    """
    ---
    reference: #{params["reference"]}
    titre: #{params["titre"]}
    auteur: #{params["auteur"]}
    competences: #{params["competences"]}
    niveau: #{params["niveau"]}
    duree: #{duree_form_max_and_min(params)}
    created_at: #{Date.utc_today()}
    revisions: []
    ---
    #{params["rubriques"]["mission"] && "rub:Mission\n" || ""}
    #{params["rubriques"]["scenario"] && "rub:Scénario\n" || ""}
    #{params["rubriques"]["aide"] && "rub:Aide\n" || ""}
    #{params["rubriques"]["recommandations"] && "rub:Recommandations\n" || ""}
    """
  end

  defp duree_form_max_and_min(params) do
    if params["duree"] do
      params["duree"]
    else
      "#{human_duree_for(params["duree_min"])} à #{human_duree_for(params["duree_max"])}"
    end
  end
  defp human_duree_for(minutes) do
    case minutes do
    15 -> "un 1/4 d’heure"
    30 -> "une 1/2 heure"
    45 -> "trois 1/4 d’heure"
    60 -> "une heure"
    90 -> "une heure 30"
    "15" -> "un 1/4 d’heure"
    "30" -> "une 1/2 heure"
    "45" -> "trois quart d’heure"
    "60" -> "une heure"
    "90" -> "une heure 30"
    _ -> "#{minutes} minutes"
    end
  end

end
