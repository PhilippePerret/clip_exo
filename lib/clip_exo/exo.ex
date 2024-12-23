# Méthodes propres à un exercice
defmodule ClipExo.Exo do

  defstruct [
    infos: %{
      path:  "",
      reference: "", 
      titre: "",
      auteur: "",
      created_at: Date.utc_today(),
      revised_at: [],
      competences: [],
      niveau: "",
      duree: "",
    },
    body: "<corps de l'exercice>",
    rubriques: []
  ]

  @folder "./_exercices/clipexo/"

  @doc """
  Retourne le contenu de l'exercice clip.exo +path+

  +path+ est une path vérifiée
  """
  def get_content_of(path) do
    File.read!(path)
  end

  @doc """
  Construction de l'exercice définit dans +exo+

  Pour le moment, +exo+ ne contient que "file_path", le chemin 
  d'accès relatif au fichier. Par défaut, on le cherche dans @folfder
  """
  def build(exo) do
    IO.puts "-> Exo.build"
    case get_path_exo(exo) do
    {:ok, path} -> 
      IO.puts("Je dois parser le fichier que j'ai trouvé")
      parse_file(path)
    {:error, error} ->
      IO.puts error
    end
  end

  def parse_file(path), do: parse_code(File.read!(path))

  @doc """
  Méthode qui prend le code +code+, en supposant qu'il est
  au format clip.exo et le transforme en table (liste) façon
  AST pour produire le document HTML.
  """
  def parse_code(code) do
    IO.puts "-> parse (avec '#{code}'')"
    code
    |> decompose_header_body()
  end

  @reg_front_matter ~r/(^|\n)---\n(?<front_matter>(?:.|\n)*)\n---\n(?<body>(.|\n)*)\z/Um
  defp decompose_header_body(code) do
    if Regex.match?(@reg_front_matter, code) do
      resultat = Regex.named_captures(@reg_front_matter, code)

      infos = get_infos_from_front_matter(resultat["front_matter"])
      bodys = get_body_from(resultat["body"])

      ok = (elem(infos, 0) == :ok && elem(bodys, 0) == :ok) && :ok || :error
      resultat = %{
        infos:  elem(infos, 1),
        body:   elem(bodys, 1),
      }
      {ok, resultat}
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
            captures["value"] |> String.trim() 
          }
        end
        end)
      |> Enum.reject(fn x -> elem(x,0) == :"" || elem(x,1) == "" end)
      |> Enum.reduce(%{}, fn tup, acc -> 
          Map.put(acc, elem(tup, 0), elem(tup, 1))
        end)
    {:ok, infos}
  end

  defp get_body_from(raw_body) do
    liste_bodys =
      String.split(raw_body, "\n")
      |> Enum.map(&analyse_body_lines(&1))
      |> Enum.reject(fn x -> elem(x,1) == "" end)

    cond do
    is_list(liste_bodys)    -> {:ok, liste_bodys}
    is_binary(liste_bodys)  -> {:error, liste_bodys}
    end
  end

  # Méthode qui analyse une ligne unique du corps de l'exercice
  defp analyse_body_lines(line) do
    line
    |> String.trim()
    |> separe_tag_from_content()
    # --- à partir d'ici, on a un Tuple {tag, content, params} --
  end

  @doc """
  Méthode qui reçoit la ligne de body (par exemple :
    "Ma simple phrase" ou
    "balise: Simple phrase avec balise" ou
    "function(true): Phrase avec balise et paramètres"
    )
  … et retourne un tuple contenant :
    { :tag|nil, "<contenu textuel>", [params]|nil }
  """
  @reg_tag_params_content ~r/^(?:(?<tag>[^\(\:)]*)(\((?<params>.*)\))?:)?(?<content>.*)$/m
  def separe_tag_from_content(line) do
    Regex.named_captures(@reg_tag_params_content, line)
    |> rationnalise_captures_line_body
  end

  defp rationnalise_captures_line_body(captures) do
    {
      rationnalise_balise_bodyline(captures["tag"]),
      rationnalise_content_bodyline(captures["content"]),
      rationnalise_params_bodyline(captures["params"])
    }
  end
  defp rationnalise_balise_bodyline(tag) do
    case tag do
    "" -> nil
    tag -> tag |> String.trim() |> String.downcase |> String.to_atom()
    end
  end
  defp rationnalise_content_bodyline(content) do
    String.trim(content)
  end
  defp rationnalise_params_bodyline(params) do
    case params do
    "" -> nil
    params -> params 
      |> String.split(",")
      |> Enum.map(fn x -> elem(Code.eval_string(String.trim(x)), 0) end)
      # TODO Ici, on pourrait apporter une protection suplémentaire : dans
      # le cas où un paramètre ne puisse pas être évalué, on le considèrerait
      # comme une simple chaine.
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
  # pas forcément encore
  defp get_path_exo(exo) do
    if exo["file_path"] do
      { :ok, Path.join([@folder, add_extensions_if_needed(exo["file_path"])]) }
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
    30 -> "une 1/2 heure"
    "30" -> "une 1/2 heure"
    60 -> "une heure"
    "60" -> "une heure"
    45 -> "trois quart d’heure"
    "45" -> "trois quart d’heure"
    _ -> "#{minutes} minutes"
    end
  end

end
