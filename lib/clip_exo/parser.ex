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
    * parser les lignes des lignes de conteneur qui peuvent aussi
      être définies par des "css.css: La ligne" pour ajouter des classes CSS

  """

  @types_conteneur %{
    raw:        "Bloc raw",
    steps:      "Liste d'étapes numérotées",
    blockcode:  "Bloc de codes",
    table:      "Table"
  }

  def parse_code(code) do
    accumulateur = %{current_conteneur: nil, lines: [], blocs: []}

    final_accumulateur =
    code 
    |> String.split("\n")
    |> Enum.reduce(accumulateur, fn line, accumulateur ->
      res = parse_line(line, accumulateur.current_conteneur)
      new_conteneur = elem(res, 1)[:conteneur]
      
      updated_accumulateur =
        cond do
        new_conteneur == nil and accumulateur.current_conteneur ->
          # On doit consigner ce conteneur
          %{
            accumulateur |
            current_conteneur: nil,
            lines: [], # on ne met pas la ligne courante, qui a été mise dans le conteneur courant
            blocs: accumulateur.blocs ++ [accumulateur.current_conteneur]
          }
        new_conteneur == nil ->
          %{
            accumulateur |
            current_conteneur: nil,
            lines: [res]          }
        new_conteneur ->
          %{
            accumulateur |
            current_conteneur: new_conteneur,
            lines: []          }
        end
      updated_accumulateur
    end)
    final_accumulateur.blocs
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
  @reg_exo_line ~r/
  ^ # début
  (?<line_classes>[a-zA-Z\.0-9_\-]+)? # une ou plusieurs classes
  \:
  (?:(?<type_line>[a-z]{1,3}|=>|\+)(?<pre_line>[ \t]+))?  # définition de la ligne dans le conteneur p.e. cr
  (?<options>\:)? # éventuellement une option
  (?<type_cont>[a-z]+)? # le type du conteneur
  (?<rest>.*) # tout ce qui reste
  $ # jusqu'à la fin
  /x
  def parse_line(line, conteneur) do
    if line == "" do
      {:ok, [type: :separator, conteneur: nil]}
    else
      case Regex.named_captures(@reg_exo_line, line) do
      nil ->
        # Une ligne sans ":", donc simple (note : elle annule le conteneur)
        {:ok, [line: %ExoLine{type: :paragraph, content: line, classes: []}, conteneur: nil]}
      captures -> 
        check_captures(captures, conteneur, line)
      end
    end
  end

  defp check_captures(%{
    "line_classes"  => line_classes,
    "type_line"     => type_line,
    "pre_line"      => pre_line,
    "options"       => options, # ne contiendra que ":" mais signifiera que +rest+ est l'option
    "type_cont"     => type_cont,
    "rest"          => rest
  }, conteneur, line) do
    cond do
      line_classes != "" ->
        {:ok, [line: %ExoLine{type: :paragraph, content: String.trim(rest), classes: String.split(line_classes, ".")}, conteneur: nil]}
      options != "" -> # une option "::" de conteneur
        if conteneur do
          conteneur = Map.put(conteneur, :options, Map.get(conteneur, :options) ++ [type_cont <> rest])
          {:ok, [type: :conteneur, conteneur: conteneur]}
        else
          {:error, "Option de conteneur sans conteneur : '#{type_cont <> rest}'"}
        end
      type_cont != "" and type_line == "" ->
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
          tline = (type_line != "") && String.trim(type_line) || nil
          content = pre_line <> type_cont <> rest
          conteneur = Map.put(conteneur, :lines, conteneur.lines ++ [%ExoLine{type: :line, content: content, tline: tline}])
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
    Map.get(@types_conteneur, String.to_atom(type_cont), false) != false
  end


end 