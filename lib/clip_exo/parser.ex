defmodule ExoParser do
  @moduledoc """
  Module qui parse le code du fichier de la définition de l'exercice .clip.exo

  Produit une liste qui contient des %ExoConteneur et des %ExoLine

  %ExoConteneur
    Un conteneur contenant des lines: [%ExoLine]
  %ExoLine
    Des lignes seules n'appartenant à aucun conteneur.

  Voir les deux structures dans le fichier exo_structures.ex

  TODO


  """

  def parse_code(code) do
    code = code <> "\n" # pour fermer l'éventuel conteneur
    accumulateur = %{current_conteneur: nil, elements: [], errors: []}

    code 
    |> String.split("\n")
    |> Enum.reduce(accumulateur, fn line, accumulateur ->
      res = parse_line(line, accumulateur.current_conteneur)
      # |> IO.inspect(label: "\nRES")

      case res do
      {:ok, res} ->
        # Une ligne parsée avec succès
        add_line_or_conteneur(res, accumulateur) # => updated_accumulator
      {:error, err_msg} ->
        # Une erreur rencontrée
        %{accumulateur | errors: accumulateur.errors ++ [err_msg]}
      end
    end)

  end

  defp add_line_or_conteneur(res, accumulateur) do
    new_conteneur = res[:conteneur] # peut être nil
    
    # updated_accumulateur =
    cond do
    new_conteneur == nil and accumulateur.current_conteneur ->
      # On doit consigner ce conteneur
      %{
        accumulateur |
        current_conteneur: nil,
        elements: accumulateur.elements ++ [accumulateur.current_conteneur]
      }
    new_conteneur == nil ->
      %{
        accumulateur |
        current_conteneur: nil,
        elements: accumulateur.elements ++ [res]
      }
    new_conteneur ->
      %{
        accumulateur |
        current_conteneur: new_conteneur
      }
    end
    |> IO.inspect(label: "\nACCU ACTUALISÉ")
    # updated_accumulateur
  end


  @doc """
  Entrée principale qui reçoit une ligne du fichier exercice et retourne
  {:ok, content, conteneur} ou {:error, message_erreur} en cas d'erreur

  Il peut y avoir ces types de lignes :

  <Paragraphe>            Un paragraphe quelconque, sans style (class regular)
  rub: Paragraphe         Paragraphe normal avec une class CSS appliquée
  rub.main: Paragraphe    Paragraphe avec deux classe CSS appliquées
  :<conteneur>            Si +conteneur+ est vide, c'est le début d'un nouveau conteneur.
                          On peut trouver les conteneur :raw, :table, :steps, :blockcode, etc.
  :   Paragraphe          Un paragraphe à mettre dans le conteneur courant. Le conteneur courant
                          doit être défini.
  :=> Paragraphe          Un résultat dans un conteneur :steps par exemple
  :+  Paragraphe          Une ligne de code à mettre en exergue dans un conteneur de type :blockcode
  
  +conteneur+
    Structure   %ExoConteneur{type: <type>, lines: [<lignes>], options: [<options>]}

  """
  @reg_cssed_paragraph ~r/^(?<classes>[a-zA-Z\.0-9_\-]+)\:(?<content>.+)$/
  @reg_exo_line ~r/
  ^ # début
  \: # commence par deux points
  (?:(?<type_line>[a-z]{1,3}|=>|\+)?(?<pre_line>[ \t]+))? # définition de la ligne dans le conteneur p.e. cr
                                                          # et espace entre deux points et contenu ligne
  (?<options>\:)? # éventuellement une option
  (?<type_cont>[a-z]+)? # le type du conteneur ou le début de ligne de conteneur
  (?<rest>.*) # tout ce qui reste
  $ # jusqu'à la fin
  /x
  def parse_line(line, conteneur) do
    cond do
    line == "" ->
       {:ok, [type: :separator, conteneur: nil]}
    Regex.match?(@reg_cssed_paragraph, line) ->
      {:ok, [line: exo_line_from_cssed_line(line), conteneur: nil]}
    true ->
      case Regex.named_captures(@reg_exo_line, line) do
      nil ->
        # Une ligne sans ":", donc simple (note : elle annule le conteneur)
        {:ok, [line: %ExoLine{type: :paragraph, content: line, classes: []}, conteneur: nil]}
      captures -> 
        check_captures(captures, conteneur, line)
      end
    end
  end

  # Traitement éventuel d'une ligne de format : «««css.css: Contenu»»»
  defp exo_line_from_cssed_line(line) do
    case Regex.named_captures(@reg_cssed_paragraph, line) do
    nil -> 
      %ExoLine{type: :line, content: line, classes: nil}
    captures ->
      %{
        "classes" => classes, 
        "content" => content
      } = captures
      %ExoLine{
        type: :line, 
        content: String.trim(content),
        classes: String.split(classes, ".")
        }
    end
  end

  defp check_captures(%{
    "type_line"     => type_line,
    "pre_line"      => pre_line,
    "options"       => options, # ne contiendra que ":" mais signifiera que +rest+ est l'option
    "type_cont"     => type_cont,
    "rest"          => rest
  }, conteneur, line) do
    cond do
      options != "" -> # une option "::" de conteneur
        if conteneur do
          conteneur = Map.put(conteneur, :options, Map.get(conteneur, :options) ++ [type_cont <> rest])
          {:ok, [type: :conteneur, conteneur: conteneur]}
        else
          {:error, "Option de conteneur sans conteneur : '#{type_cont <> rest}'"}
        end
      type_cont != "" and type_line == "" and pre_line == "" ->
        if type_cont_valid?(type_cont) do
          if rest == "" do
            {:ok, [type: :conteneur, conteneur: %ExoConteneur{type: String.to_atom(type_cont)}]}
          else
            {:ok, [type: :conteneur, conteneur: %ExoConteneur{type: String.to_atom(type_cont)}, params: rest]}
          end
        else
          {:error, "Type de conteneur inconnu : '#{type_cont}'"}
        end
      type_line != "" || rest != "" ->
        if conteneur do
          # Je dois mettre la ligne dans le conteneur
          tline = if (type_line != ""), do: String.trim(type_line), else: nil
          # IO.inspect(type_cont <> rest, label: "\nLine envoyée")
          # IO.inspect(pre_line, label: "\nPré-line")
          exoline = exo_line_from_cssed_line(type_cont <> rest)
          exoline = Map.merge(exoline, %{preline: pre_line, tline: tline})
          conteneur = Map.put(conteneur, :lines, conteneur.lines ++ [exoline])
          {:ok, [conteneur: conteneur]}
        else
          {:error, "Ligne de conteneur sans conteneur : '#{line}'"}
        end
      true -> 
        {:error, "Aucune correspondance => Impossible d'analyse la ligne '#{line}'…"}
    end

  end

  # Return le conteneur mais seulement s'il est connu
  defp type_cont_valid?(type_cont) do
    Map.get(ExoConteneur.get_types_conteneur(), String.to_atom(type_cont), false) != false
  end


end 