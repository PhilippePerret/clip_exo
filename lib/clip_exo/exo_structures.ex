defmodule ExoConteneur do
  defstruct [
    type:     nil,  # le type de conteneur (cf @types_conteneur)
    lines:    [],   # Liste des %ExoLine
    options:  []
  ]

  # Types possible de conteneur
  #
  # Si un type est ajouté, il faut ajouter son traitement des lignes
  # dans exo_inner_formater.ex (ExoLine.Builder.to_htm/2)
  @types_conteneur %{
    raw:        "Bloc raw",
    etapes:      "Liste d'étapes numérotées",
    blockcode:  "Bloc de codes",
    table:      "Table"
  }

  def get_types_conteneur(), do: @types_conteneur

  
end #/defmodule ExoConteneur

defmodule ExoLine do
  defstruct [
    type:     :line,  # toujours ? :line
    content:  nil, 
    classes:  nil,    # ou liste des css
    tline:    nil,    # ou le type de line (caractères juste après ":")
    preline:  nil     # ou les espaces/tabulations avant
  ]

  def classes_css(exoline) do
    ( ["line"] ++ (exoline.classes || []) ) |> Enum.join(" ")
  end
  def classes_css(exoline, conteneur) do
    class_added = case exoline.tline do
      "=>" -> " resultat"
      _ -> ""
    end
    class_by_type_conteur = case conteneur.type do
      :etapes -> " pas"
      :blockcode -> ""
      _ -> ""
    end
    "#{classes_css(exoline)}#{class_by_type_conteur}#{class_added}"
  end

  # Ce qu'il faut ajouter avant le contenu d'un blockcode
  def pre_line_in_blockcode(exoline) do
    len = String.length( (exoline.tline || "") <> (exoline.preline || "") )
    String.duplicate(" ", len - 2)
  end
end #/defmodule ExoLine


defmodule ExoSeparator do
  defstruct [
    type: :separator
  ]
end #/defmodule ExoSeparator