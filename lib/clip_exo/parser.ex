defmodule ExoParser do

  @types_conteneur %{
    raw:        "Bloc raw",
    steps:      "Liste d'étapes numérotées",
    blockcode:  "Bloc de codes",
    table:      "Table"
  }

  def parse_code(code) do

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
  (?<type_line>[a-z\=\>]+[ \t])?  # définition de la ligne dans le conteneur p.e. cr
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
        {:ok, [type: :paragraph, content: line, classes: [], conteneur: nil]}
      captures -> 
        check_captures(captures, conteneur, line)
      end
    end
  end

  defp check_captures(%{
    "line_classes"  => line_classes,
    "type_line"     => type_line,
    "options"       => options, # ne contiendra que ":" mais signifiera que +rest+ est l'option
    "type_cont"     => type_cont,
    "rest"          => rest
  }, conteneur, line) do
    cond do
      line_classes != "" ->
        {:ok, [type: :paragraph, content: String.trim(rest), classes: String.split(line_classes, "."), conteneur: nil]}
      options != "" -> # une option "::" de conteneur
        if conteneur do
          conteneur = Map.put(conteneur, :options, Map.get(conteneur, :options) ++ [type_cont <> rest])
          {:ok, [type: :conteneur, conteneur: conteneur]}
        else
          {:error, "Option de conteneur sans conteneur : '#{type_cont <> rest}'"}
        end
      type_cont != "" ->
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
          tline = (type_line != "") && String.to_atom(type_line) || :line
          conteneur = Map.put(conteneur, :lines, Map.get(conteneur, :lines) ++ [[type: tline, content: rest]])
          # TODO Peut-être faire une structure %ExoConteneurLine{:content, :type}
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