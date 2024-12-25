defmodule ExoInnerFormater do
  @moduledoc """

  MODULE PRINCIPAL QUI CONSTRUIT LE CORPS DE L'EXERCICE

  En entrée, on a le code parsé avec ExoParser (donc un 
  "accumulateur") et en sortie un code HTML formaté

  """

  @doc """
  Function principal qui construit l'exercice à partir de la liste 
  d'élément +element+ retourné par l'accumulateur de 
  ExoParser.parse_code

  """
  def build(elements, %ClipExo.Exo{} = exo, options \\ []) do
    elements
    |> Enum.map(&build_element(&1))
    |> Enum.join("")
  end

  @doc """
  Function qui construit l'élément
  """
  def build_element(%ExoConteneur{} = conteneur) do
    ExoConteneur.Builder.to_html(conteneur)
  end
  def build_element(%ExoLine{} = exoline) do
    ExoLine.Builder.to_html(exoline)
  end
  def build_element(%ExoLine{} = exoline, %ExoConteneur{} = conteneur) do
    ExoLine.Builder.to_html(exoline, conteneur)
  end

  def build_element(%ExoSeparator{} = _separator) do
    "<div>Construction d'un séparateur</div>"
  end

  def build_element(element) do

    "<div>Construction d'un élément de type inconnu</div>"
  end

end #/module ExoInnerFormater




defmodule ExoLine.Builder do

  # Formatage d'une ligne dans un conteneur
  def to_html(%ExoLine{} = exoline, %ExoConteneur{type: :blockcode} = conteneur) do
    css = "line#{if exoline.tline == "+", do: "m"}"
    "<div class=\"#{css}\">#{traite_line_type_code(exoline)}</div>"
  end
  def to_html(%ExoLine{} = exoline, %ExoConteneur{type: :table} = conteneur) do
    "LINE dans TABLE : #{exoline.content}"
  end
  def to_html(%ExoLine{} = exoline, %ExoConteneur{type: :etapes} = conteneur) do
    css = "pas#{if exoline.tline == "=>", do: " resultat", else: ""}"
    "<div class=\"#{css}\">#{exoline.content}</div>"
  end
  def to_html(%ExoLine{} = exoline, %ExoConteneur{type: :raw} = conteneur) do
    "LINE dans RAW : #{exoline.content}"
  end

  def to_html(%ExoLine{} = exoline, %ExoConteneur{} = conteneur) do
    "<div class=\"warning\">Line dans CONTENEUR INCONNU (#{conteneur.type}) : #{exoline.content}</div>"
  end

  # Formatage d'une ligne hors conteneur
  def to_html(%ExoLine{} = exoline) do
    "Line séparée #{exoline.content}"
  end
  

  defp traite_line_type_code(exoline) do
    exoline.content
    |> String.replace("<", "&lt;")
    |> String.replace("\t", "  ")
    |> String.replace([" ", " "], "&nbsp;")
    # |> IO.inspect(label: "\nString de code")
  end
  

end #/ExoLine.Builder


defmodule ExoConteneur.Builder do
  def to_html(conteneur) do
    "<section class=\"#{conteneur.type}\">"
    <> (conteneur.lines
    |> Enum.map(&ExoInnerFormater.build_element(&1, conteneur))
    |> Enum.join(""))
    <> "</section>"
  end
end