defmodule ExoInnerFormater do
  @moduledoc """

  MODULE PRINCIPAL QUI CONSTRUIT LE CORPS DE L'EXERCICE

  En entrée, on a le code parsé avec ExoParser (donc un 
  "accumulateur") et en sortie un code HTML formaté

  """

  @doc """
  Liste des classes CSS qu'on peut appliquer aux paragraphes.

  Dans l'idée, on peut avoir n'importe quelle classe à partir du
  moment où elle est définie dans clip_exo.css ou dans le fichier
  CSS propre à l'exercice (non encore implémenté)
  """
  @liste_classes_paragraphe [
    {"rub", "Titre de rubrique (p.e. « Mission » ou « Aide »)" },
    {"rubi", "Pour 'rub inline'. Comme si dessus, mais sur une seule ligne"},
    {"cadre", "Pour un paragraphe dans un cadre"}
  ]

  def get_paragraph_styles() do
    @liste_classes_paragraphe 
  end

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
  Function qui construit l'élément en fonction de son exo-type
  (%ExoConteneur, %ExoLine, etc.)
  """
  def build_element(%ExoConteneur{} = conteneur) do
    ExoConteneur.Builder.to_html(conteneur)
  end
  def build_element(%ExoLine{} = exoline) do
    ExoLine.Builder.to_html(exoline_with_formated_content(exoline))
  end
  def build_element(%ExoSeparator{} = _separator) do
    "<div class=\"separator\"></div>"
  end
  def build_element(element) do
    "<div>Construction d'un élément de type inconnu : #{element.content}</div>"
  end

  def build_element(%ExoLine{} = exoline, %ExoConteneur{} = conteneur) do
    ExoLine.Builder.to_html(exoline_with_formated_content(exoline), conteneur)
  end

  defp exoline_with_formated_content(exoline) do
    fcontent = 
      exoline.content
      |> StringTo.html()
      |> add_pictos_if_required(exoline)
    %{exoline | fcontent: fcontent}
  end

  defp add_pictos_if_required(content, %ExoLine{tline: nil}) do
    content
  end
  @liste_pictos_actions ["clavier", "cle", "clic", "coche", "menu", "mesure", "radio", "repete", "souris"]
  defp add_pictos_if_required(content, %ExoLine{:tline => tline}) do
    if Enum.member?(@liste_pictos_actions, tline) do
      "<div class=\"picto #{tline}\"></div><span class=\"text-picto\">#{content}</span>"
    else
      content
    end
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
          # La cellule être stylée avec «««css: Le texte»»»
          exo_cel = cel |> String.trim() |> ExoParser.parse_cssed_line_content()
          # => %ExoLine{}
          td_class =
            case exo_cel.classes do
            nil -> ""
            _   -> " class=\"#{Enum.join(exo_cel.classes, " ")}\""
            end
          "<td#{td_class}>#{String.trim(StringTo.html(cel))}</td>"
        end)
      |> Enum.join("")
      |> String.replace("__VIRG__", "\\,")
    "<tr>" <> row <> "</tr>"
  end
  # - etapes -
  def to_html(%ExoLine{} = exoline, %ExoConteneur{type: :etapes} = conteneur) do
    "<div class=\"#{ExoLine.classes_css(exoline, conteneur)}\">#{exoline.fcontent}</div>"
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
    "<div class=\"#{ExoLine.classes_css(exoline)}\">#{exoline.fcontent}</div>"
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
    css = ExoConteneur.classes_css(conteneur)
    "<#{cont_tag} class=\"#{css}\">"
    <> (conteneur.lines
        |> Enum.map(&ExoInnerFormater.build_element(&1, conteneur))
        |> Enum.join(""))
    <> "</#{cont_tag}>"
  end
end # /module ExoConteneur.Builder