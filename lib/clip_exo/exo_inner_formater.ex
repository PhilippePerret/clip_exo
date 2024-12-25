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
  def build(elements, %ClipExo.Exo{} = _exo, _options \\ []) do
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
  def build_element(%ExoSeparator{} = _separator) do
    "<div class=\"separator\"></div>"
  end
  def build_element(element) do
    "<div>Construction d'un élément de type inconnu : #{element.content}</div>"
  end

  def build_element(%ExoLine{} = exoline, %ExoConteneur{} = conteneur) do
    ExoLine.Builder.to_html(exoline, conteneur)
  end


end #/module ExoInnerFormater




defmodule ExoLine.Builder do

  # Formatage d'une ligne dans un conteneur
  # - blockcode -
  def to_html(%ExoLine{} = exoline, %ExoConteneur{type: :blockcode} = _conteneur) do
    css = "line#{if exoline.tline == "+", do: "m"}"
    "<div class=\"#{css}\">#{ExoLine.pre_line_in_blockcode(exoline)}#{traite_line_type_code(exoline)}</div>"
  end
  # - table -
  def to_html(%ExoLine{} = exoline, %ExoConteneur{type: :table} = _conteneur) do
    row =
      exoline.content
      |> String.replace("\\,", "__VIRG__")
      |> String.split(",")
      |> Enum.map(fn cel -> 
          # TODO elles peuvent être stylé avec «««css: Le texte»»»
          "<td>#{String.trim(cel)}</td>"
        end)
      |> Enum.join("")
      |> String.replace("__VIRG__", "\\,")
    "<tr>" <> row <> "</tr>"
  end
  # - etapes -
  def to_html(%ExoLine{} = exoline, %ExoConteneur{type: :etapes} = conteneur) do
    "<div class=\"#{ExoLine.classes_css(exoline, conteneur)}\">#{exoline.content}</div>"
  end
  # - raw -
  def to_html(%ExoLine{} = exoline, %ExoConteneur{type: :raw} = conteneur) do
    "<div class=\"#{ExoLine.classes_css(exoline, conteneur)}\">#{traite_line_type_code(exoline)}</div>"
  end

  def to_html(%ExoLine{} = exoline, %ExoConteneur{} = conteneur) do
    "<div class=\"warning\">Line dans CONTENEUR INCONNU (#{conteneur.type}) : #{exoline.content}</div>"
  end

  # Formatage d'une ligne hors conteneur
  def to_html(%ExoLine{} = exoline) do
    "<div class=\"#{ExoLine.classes_css(exoline)}\">#{exoline.content}</div>"
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
    cont_tag = case conteneur.type do
      :table  -> "table"
      _       -> "section"
      end
    "<#{cont_tag} class=\"conteneur #{conteneur.type}\">"
    <> (conteneur.lines
    |> Enum.map(&ExoInnerFormater.build_element(&1, conteneur))
    |> Enum.join(""))
    <> "</#{cont_tag}>"
  end
end # /module ExoConteneur.Builder