defmodule ExoOptionsConteneur do
  defstruct [
    borders:    ["h", "v"],  # les bordures des tables par défaut
    cols_label: [],     # label des colonnes de table par défaut
    cols_width: [],     # largeur des colonnes de table par défaut
    cols_class: [],     # classes CSS des colonnes de table par défaut
    cols_align: [],     # alignement des colones de table par défaut
    cols_pad:   [],     # padding pour chaque colonnes
    legende:    nil,    # la légende
    define_cols: false, # sera mis à true si les colonnes sont définis
    cols_count: nil,    # Nombre de colonnes
    cols_flex:  false,  # Mis à true en interne quand une colonne 
                        # définit la largeur "_". Ça permet de mettre
                        # le style de la table à width:100%
    cols:       "",     # Pour la construction interne du colgroup
    section_header: "", # À ajouter juste après <section...> ou <table...>
    section_footer: "", # À ajouter juste avant </section> ou </table>
    no_num:     false,  # Pour les étapes et les codes, suppression des numéros
    extra_options: []   # Les options supplémentaires éventuelles
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
    liste:      "Liste simple",
    etapes:      "Liste d'étapes numérotées",
    blockcode:  "Bloc de codes",
    table:      "Table",
    qcm:        "Questionnaire à Choix Multiple"
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
    ++  for option <- [:no_num] do
          if Map.get(conteneur.options, option) == true, do: Atom.to_string(option), else: nil
        end |> Enum.reject(fn x -> is_nil(x) end)
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
    fcontent: nil,    # Contenu formaté
    classes:  nil,    # ou liste des css (pour un affichage
                      # on ajoute la classe 'horizontal')
    tline:    nil,    # ou le type de line (caractères juste après ":")
    preline:  nil,    # ou les espaces/tabulations avant
    data:     nil     # Pour mettre n'importe quelle donnée. Par
                      # exemple, pour les QCM, on y met le nombre de 
                      # points par réponse.
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
    if len > 2 do
      String.duplicate(" ", len - 2)
    else
      ""
    end
  end
end #/defmodule ExoLine


defmodule ExoSeparator do
  defstruct [
    type: :separator
  ]
end #/defmodule ExoSeparator