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

  # Formatage d'un conteneur
  # ------------------------
  # @usage
  #
  #   ExoConteneur.to_html(conteneur)) => String
  #
  def to_html(%ExoConteneur{} = conteneur) do
    "Conteneur de type #{conteneur.type}"
    [
      first_line_by_conteneur(conteneur),
      conteneur.lines |> Enum.map(fn exoline ->
        exoline.content # TODO
      end)
      |> Enum.join(""),
      last_line_by_conteneur(conteneur)
    ] |> Enum.join("")
  end
  
  defp first_line_by_conteneur(conteneur) do
    "<div class=\"conteneur #{conteneur.type}\">"
  end
  defp last_line_by_conteneur(_conteneur) do
    "</div>"
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

  # # Formatage d'une ligne dans un conteneur
  # def to_html(%ExoLine{} = exo, %ExoConteneur{} = _conteneur) do
  #   "Line dans conteneur #{exo.content}"
  # end
  # # Formatage d'une ligne hors conteneur
  # def to_html(%ExoLine{} = exo, nil) do
  #   "Line hors conteneur #{exo.content}"
  # end

end #/defmodule ExoLine


defmodule ExoSeparator do
  defstruct [
    type: :separator
  ]
end #/defmodule ExoSeparator