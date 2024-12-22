# Méthodes propres à un exercice
defmodule ClipExo.Exo do

  defstruct [
    infos: %{
      titre: "<titre de l'exercice>",
      auteur: "<Auteur de l'exercice>",
      created_at: NaiveDateTime.utc_now(),
      revised_at: []
    },
    body: "<corps de l'exercice>"
  ]

  @folder "./_exercices/clipexo/"

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




  # Pour définir précisément le chemin d'accès au fichier de l'exercice
  defp get_path_exo(exo) do
    exo =
      if exo["file_path"] do
        paths = String.split(exo["file_path"], ".")
        exts  = [Enum.fetch!(paths, -2), Enum.fetch!(paths, -1)]
        |> IO.inspect(label: "\nexts")
        path =
          case exts do
            ["clip", "exo"] -> exo["file_path"]
            [_, "clip"]       -> exo["file_path"] <> ".exo"
            _ -> exo["file_path"] <> ".clip.exo"
          end
        
        Map.put(exo, "file_path", path)
      end
    path = Path.join([@folder, exo["file_path"] || "[nom fichier manquant]"])

    if File.exists?(path) do
      {:ok, path}
    else
      {:error, "Impossible de trouver '#{path}'"}
    end
  end




  def build_preformated_exo(_params) do
    IO.puts "Je dois apprendre à créer l'exercice préformaté"
    {:error, "Je ne sais pas encore créer l'exercice préformaté."}
  end
end
