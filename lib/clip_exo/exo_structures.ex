defmodule ExoOptionsConteneur do
  defstruct [
    borders:    ["h", "v"],  # les bordures des tables par défaut
    cols_label: [],  # label des colonnes de table par défaut
    cols_width: [],  # largeur des colonnes de table par défaut
    cols_class: [],  # classes CSS des colonnes de table par défaut
    cols_align: [],  # alignement des colones de table par défaut
    cols_pad:   [],  # padding pour chaque colonnes
    no_num:     false, # Pour les étapes et les codes, suppression des numéros
  ]
end

defmodule ExoConteneur do
  defstruct [
    type:     nil,      # le type de conteneur (cf @types_conteneur)
    lines:    [],       # Liste des %ExoLine
    options:  %ExoOptionsConteneur{}, # options (cf. ci-dessus)
    raw_options: []     # Options pendant la relève (une liste de strings)
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

  def classes_css(%ExoConteneur{type: :table} = conteneur) do
    IO.inspect(conteneur.options, label: "\nOPTIONS DE TABLE")
    default_css(conteneur)
    ++ ["borders-" <> Enum.join(conteneur.options.borders, "")]
    |> Enum.join(" ")
  end
  def classes_css(conteneur) do
    default_css(conteneur)
    |> Enum.join(" ")
  end

  defp default_css(conteneur) do
    ["conteneur", "#{conteneur.type}"]
  end


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