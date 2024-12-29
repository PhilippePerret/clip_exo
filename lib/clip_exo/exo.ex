# Méthodes propres à un exercice
defmodule ClipExo.Exo do

  alias ClipExo.ExoBuilder, as: Builder
  alias Jason

  defstruct [
    infos: %{
      name: nil,
      path:  nil,
      folder: nil,
      reference: nil,
      titre: nil,
      auteur: nil,
      created_at: Date.utc_today(),
      logiciels: nil,
      revisions: nil, # ou string jj/mm/aaaa (Prénom NOM), etc.
      competences: [],
      niveau: nil,
      duree: nil,
      css_files: nil
    },
    body:       "contenu brut de l'exercice",
    body_html:  nil,  # le contenu formaté
    rubriques:  [],   # pour les rubriques des infos
    document_formateur_required: false,
    formateur:  false,  # pour indiquer, en cours de fabrication, s'il 
                        # s'agit de la fabrication du document pour le 
                        # formateur ou pour le participant (en fait, un
                        # seul style (admin) diffère l'un de l'autre)
    suivi: nil        # Pour le suivi de la construction
  ]


  @data_rubriques [
    {"mission", "Mission"},
    {"objectif", "Objectif"},
    {"scenario","Scénario"},
    {"aide", "Aide"},
    {"recommandations","Recommandations"}
  ]
  def get_data_rubriques, do: @data_rubriques

  @data_niveaux [
    {"0", "Grand débutant"}, 
    {"1", "Débutant"}, 
    {"2", "Initié"},
    {"3", "Intermédiaire"},
    {"4", "Expert"}
  ]
  def get_data_niveaux, do: @data_niveaux


  @folder "./_exercices/clipexo/"
  @html_folder "./_exercices/html"
  
  @reg_path ~r/^[^\W]+$/

  @doc """
  Fonction qui vérifie la validité des données pour la création du
  fichier de données de l'exercice.
  Note : c'est toujours pour la création. Car ensuite, une fois que
  le fichier est créé, on l'édite pour le modifier.
  +data+ Données provenant du formulaire de data_exo_form.html.heex

  """
  def data_valid?(data) do
    # IO.inspect(data, label: "\nDATA in data_valid?")

    cond do
    is_nil(data) ->
      {:error, "Aucune donnée envoyée pour validation…"}
    data["path"] == "" ->
      {:error, "Il faut impérativement fournir le chemin dans ./_exercices/clipexo/"}
    not (data["path"] =~ @reg_path) -> 
      {:error, "Le chemin doit être d'un format valide (pas d'espaces, etc.)"}
    File.exists?(get_path_exo!(data)) ->
      {:error, "Le fichier '#{data["path"]}' existe déjà."}
    missed = not_all_data_required?(data) ->
      {:error, ["Des données manquent : #{missed}.", "Si vous ne voulez fournir que les données minimales, cocher la case des données partielles."]}
    duree_min_invalid?(data["duree_min"]) ->
      {:error, "Un exercice ne peut pas faire moins d'un quart d'heure…"}
    duree_max_invalid?(data["duree_max"]) ->
      {:error, "Un exercice ne peut pas durer plus de 4 heures…"}
    true ->
      {:ok, data}
    end
  end

  # Retourne nil si toutes les données sont fournies ou que la case "accepter les données partielles" est
  # cochée.
  # Note : la propriété obligatoire "path" est déjà checkée
  defp not_all_data_required?(data) do
    # Si cette propriété est vraie, on accepte de ne pas avoir toutes
    # les données. Seule "path" est vraiment nécessaire.
    accept_partial_data = StringTo.value(data["accept_partial_data"])
    if accept_partial_data do
      false # donc valide
    else
      data
      |> Enum.filter(fn {_x, v} -> v == "" end)
      |> Enum.map(fn {x, _v} -> 
        x 
        |> String.replace_leading(String.at(x, 0), String.upcase(String.at(x, 0)))
        |> String.replace("_", " ")
      end)
      |> Enum.join(", ")
      |> PPString.nil_if_empty()
    end
  end

  defp duree_min_invalid?(duree_min) when duree_min == "" do
    false
  end
  defp duree_min_invalid?(duree_min) do
    String.to_integer(duree_min) < 15
  end

  defp duree_max_invalid?(duree_max) when duree_max == "" do
    false
  end
  defp duree_max_invalid?(duree_min) do
    String.to_integer(duree_min) > 3600 * 4
  end



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

  Pour le moment, +params_exo+ ne contient que "path", le chemin
  d'accès relatif au fichier. Par défaut, on le cherche dans @folfder.
  Si cette donnée n'est pas donnée (champ laissé vide), on essaie de 
  prendre le dernier traitement effectué.
  """
  def build(params_exo, options \\ %{}) do
    IO.inspect(params_exo, label: "\nPARAMS_EXO")
    params_exo =
      if params_exo["path"] |> PPString.nil_if_empty() |> is_nil() do
        rappel_last_traitement() || raise("Il faut donner le path du fichier exercice.")
      else
        memo_last_traitement(params_exo)
      end

    with  {:ok, path} <- get_path_exo(params_exo),
          {:ok, exo}  <- parse_whole_file(path),
          {:ok, exo}  <- build_all_files(exo),
          {:ok, exo}  <- copy_required_files(exo),
          {:ok, exo}  <- open_exo_html_folder(exo, options) do
            {:ok, exo}
    else
      {:error, message_erreur} ->
        {:error, message_erreur}
    end
  end

  @path_memo_file ".last_traitement"
  def rappel_last_traitement() do
    if File.exists?(@path_memo_file) do
      @path_memo_file |> File.read!() |> Jason.decode!()
    else nil end
  end
  def memo_last_traitement(params) do
    File.write(@path_memo_file, Jason.encode!(params), [:utf8])
    params # pour simplifier le code appelant
  end

  # Retourne le dernier path utilisé, if any
  def last_path() do
    if memo = rappel_last_traitement() do
      memo["path"]
    else
      nil
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
  + Le document du formateur si nécessaire.
  """
  def build_all_files(%ClipExo.Exo{} = exo) do
    IO.puts "--> build_all_files"
    suivi = exo.suivi || ["Début de la construction"]

    suivi = suivi ++ [case Builder.build_file_specs(exo) do
      {:ok, _exo} -> "👍 Construction du fichier des caractéristiques"
      {:error, msg} -> "💣 Échec de la construction du fichier des caractéristiques : " <> msg
    end]

    suivi = suivi ++ [case Builder.build_file_exo(exo) do
      {:ok, _exo} -> "👍 Construction du fichier de l'exercice"
      {:error, msg} -> "💣 Échec de la construction du fichier de l'exercice : " <> msg
    end]

    suivi = if exo.document_formateur_required do
      exo = %{ exo | formateur: true }
      suivi ++ [case Builder.build_file_exo(exo) do
        {:ok, _exo} -> "👍 Construction du fichier formateur"
        {:error, msg} -> "💣 Échec de la construction du fichier formateur : " <> msg
      end]
    else suivi end

    exo = %{exo | suivi: suivi}

    IO.puts "<-- build_all_files"
    {:ok, exo}
  end

  ###################################################################

  @doc """
  Méthode qui prend le code +code+, en supposant qu'il est
  au format clip.exo et le transforme en table (liste) façon
  AST pour produire le document HTML.

  return {:ok, %ClipExo.Exo} ou {:error, "message d'erreur"}
  """
  def parse_whole_file_code(code) do
    code
    |> decompose_header_and_body()
  end

  @reg_front_matter ~r/(^|\n)---\n(?<front_matter>(?:.|\n)*)\n---\n(?<body>(.|\n)*)\z/Um
  @reg_for_formateur ~r/(admin\:|\.admin|\:qcm)/
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

      # On regarde tout de suite s'il faudra un document formateur
      # (on le fait si a) le document contient des tyles 'admin' ou
      #  b) si le document contient un QCM
      exo = %{ exo | document_formateur_required: Regex.match?(@reg_for_formateur, body)}

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
      _ -> value
    end
  end


  @doc """
  Ouvre le dossier html de l'exercice dans le finder
  """
  def open_exo_html_folder(exo, options) do
    if options[:open_folder] do
      System.shell("open \"#{Path.expand(Builder.exo_html_folder(exo))}\"")
      {:ok, exo}
    else
      {:ok, exo}
    end
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
  # pas forcément encore.
  # On peut fournir soit le +path+ (string) soit la map des données
  defp get_path_exo(exo_filename) when is_binary(exo_filename) do
    if exo_filename do
      { :ok, Path.join([@folder, add_extensions_if_needed(exo_filename)]) }
    else
      { :error, "Il faut définir au moins le nom du fichier."}
    end
  end
  defp get_path_exo(params_exo) do
    get_path_exo(params_exo["path"] || "indéfini")
  end

  defp get_path_exo!(exo_filename) do
    case get_path_exo(exo_filename) do
    {:ok, path} -> path
    {:error, msg_err} -> raise msg_err
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
    |> IO.inspect(label: "\nPARAMS pour construction du fichier des données")
    exo_name = params["path"]
    exo_filename = add_extensions_if_needed(exo_name)
    params    = %{ params | "path" => exo_filename }
    exo_path  = Path.join([@folder, exo_filename])
    cond do
    exo_filename == ".clip.exo" ->
      {:error, "Il faut fournir le nom du fichier"}
    File.exists?(exo_path) ->
      {:error, "Un fichier d’exercice porte déjà le nom #{exo_name}\n(#{exo_path})"}
    true ->
      # On peut créer le fichier exercice
      File.write!(exo_path, modele_preformated(params), [:utf8])
      {:ok, params}
    end
  end

  def modele_preformated(params) do
    IO.inspect(params, label: "\nParams in modele_preformated")

    rubriques = 
      @data_rubriques
      |> Enum.filter(fn {value, _label} -> Enum.member?(params["rubriques"], value) end)
      |> Enum.map(fn {_value, label} -> "rub: #{label}" end)
      |> Enum.join("\n\n\n")

    """
    ---
    titre: #{params["titre"]}
    reference: #{params["reference"]}
    name: #{params["name"]}
    path: #{params["path"]}
    competences: [#{params["competences"]}]
    niveau: #{formated_niveau(params)}
    duree: #{duree_form_max_and_min(params)}
    auteur: #{params["auteur"]}
    created_at: #{Date.utc_today()}
    revisions: [#{params["revisions"]}]
    ---
    #{rubriques}
    """
  end

  defp formated_niveau(params) do
    {_index, label} = Enum.at(@data_niveaux, String.to_integer(params["niveau"] || 0))
    label
  end

  defp duree_form_max_and_min(params) do
    duree_min = params["duree_min"] || "30"
    duree_max = params["duree_max"] || "90"
    "[#{duree_min}, #{duree_max}]"
  end

end
