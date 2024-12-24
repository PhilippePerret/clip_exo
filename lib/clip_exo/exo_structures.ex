defmodule ExoConteneur do
  defstruct type: nil, lines: [], options: []

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
  defstruct type: nil, content: nil, classes: nil, tline: nil

  # Formatage d'une ligne dans un conteneur
  def to_html(%ExoLine{} = exo, %ExoConteneur{} = _conteneur) do
    "Line dans conteneur #{exo.content}"
  end
  # Formatage d'une ligne hors conteneur
  def to_html(%ExoLine{} = exo, nil) do
    "Line hors conteneur #{exo.content}"
  end

end #/defmodule ExoLine