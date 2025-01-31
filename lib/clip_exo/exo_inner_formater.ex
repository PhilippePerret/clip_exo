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
  CSS propre à l'exercice [non encore implémenté]
  """
  @liste_classes_paragraphe [
    {"rub", "Titre de rubrique (p.e. « Mission » ou « Aide »)" },
    {"rubi", "Pour 'rub inline'. Comme si dessus, mais sur une seule ligne"},
    {"cadre", "Pour un paragraphe dans un cadre"},
    {"doigt", "Pour « pointer » un texte"}
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
  # - ligne de TABLE -
  def to_html(%ExoLine{} = exoline, %ExoConteneur{type: :table} = conteneur) do
    options = conteneur.options
    row =
      exoline.content
      |> StringTo.list()
      |> Enum.with_index()
      |> Enum.map(fn {cel, index} -> 
          # La cellule être stylée avec «««css: Le texte»»»
          exo_cel = cel 
            |> String.trim() 
            |> ExoParser.parse_cssed_line_content()
          # => %ExoLine{}

          # On récolte les classes qui peuvent être dans les options
          # de colonnes.
          classes = []
          # Des classes peuvent venir des cols_class ou cols_align
          classes = 
            for property <- [:cols_class, :cols_align] do
              case Enum.at(Map.get(options, property), index) do
              nil -> classes
              col_attr -> classes ++ [col_attr]
              end
            end

          # classes =
          # case Enum.at(options.cols_class, index) do
          # nil -> classes
          # col_attr -> classes ++ [col_attr]
          # end
          # classes =
          # case Enum.at(options.cols_align, index) do
          # nil -> classes
          # col_attr -> classes ++ [col_attr]

          td_class =
            if Enum.any?(classes) do
              " class=\"#{Enum.join(classes, " ")}\""
            else "" end
          "<td#{td_class}>#{String.trim(StringTo.html(exo_cel.content))}</td>"
        end)
      |> Enum.join("")
    "<tr>" <> row <> "</tr>"
  end
  # - Ligne de LISTE -
  def to_html(%ExoLine{} = exoline, %ExoConteneur{type: :liste} = _conteneur) do
    "<li>#{exoline.fcontent}</li>"
  end
  # - Ligne d'ÉTAPES -
  def to_html(%ExoLine{} = exoline, %ExoConteneur{type: :etapes} = conteneur) do
    "<div class=\"#{ExoLine.classes_css(exoline, conteneur)}\">#{exoline.fcontent}</div>"
  end
  # - Ligne de RAW -
  def to_html(%ExoLine{} = exoline, %ExoConteneur{type: :raw} = conteneur) do
    "<div class=\"#{ExoLine.classes_css(exoline, conteneur)}\">#{traite_line_type_code(exoline)}</div>"
  end

  # - Ligne de QCM -
  #
  # Les lignes d'un QCM ont un type (tline) qui peut commencer par :
  #   Q<type de réponses> Pour la question
  #   r<nombre point>     Pour la réponse
  # C'est donc la première lettre qui désigne le type
  def to_html(%ExoLine{} = exoline, %ExoConteneur{type: :qcm} = conteneur) do
    cond do
    is_nil(exoline.tline) ->
      "<div class=\"warning\">Ligne sans tline : '#{exoline.content}' (#{inspect(exoline)})</div>"
    String.at(exoline.tline, 0) == "q" -> 
      # Une question
      classes = ExoLine.classes_css(exoline, conteneur)
      "<div class=\"question #{classes}\">#{exoline.fcontent}</div>" 
      <> "<div class=\"nombre_reponses\">" <> if Enum.member?(String.split(classes, " "), "radio") do
        "(une seule bonne réponse)"
      else
        "(plusieurs réponses possibles)"
      end <> "</div>"
    true ->
      # Une réponse
      "<span data-points=\"#{exoline.data.points}\" class=\"reponse #{ExoLine.classes_css(exoline, conteneur)}\">#{exoline.fcontent}</span>"
    end
  end

  # Erreur : mauvais conteneur
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

  def to_html(%{type: :table} = conteneur) do
    # Ici, on doit préparer la table en fonction de ses options
    options = conteneur.options
    if Enum.any?(options.cols_label) do
      IO.puts "Il faut construire une première ligne de labels"
    end

    options = 
    if Enum.empty?(options.cols_width) do
      options
    else
      # Des largeurs de colonnes sont définies. Il y a deux choses à
      # faire :
      #   1) s'assurer que les unités de chaque colonne soient 
      #      bien définies (car on peut donner les nombre de 
      #      pixels seulement)
      #   2) remplacer l'éventuelle valeur "_" par le reste.
      #
      collector = # %{total: 0, unite: nil, flex_value: false}
      options.cols_width
      |> Enum.reduce(%{total: 0, unite: nil, flex_value: false, values: []}, fn x, acc -> 
          # IO.inspect(x, label: "Traitement de x")
          xx = StringTo.value(x)
          # IO.inspect(xx, label: "XX")
          cond do
          is_integer(xx) || is_float(xx) -> 
            Map.merge(acc, %{
              total: acc.total + xx,
              values: acc.values ++ ["#{xx}px"]
            })
          x == "_" -> 
            Map.merge(acc, %{
              flex_value: true,
              values: acc.values ++ ["_"]
            })
          %{type: :pourcent} = xx  ->
            Map.merge(acc, %{
              unite: :pourcent,
              total: acc.total + xx.value,
              values: acc.values ++ [xx.raw_value]
            })
          %{type: :size}     = xx  ->
            Map.merge(acc, %{
              unite: xx.unity,
              total: acc.total + xx.value,
              values: acc.values ++ [xx.raw_value]
            })
          true -> 
            %{ acc | values: acc.values ++ [xx] }
          end
        end)
        # |> IO.inspect(label: "/nRésultat de Enum.Reduce")

      final_cols_width = 
      collector.values
      |> Enum.map(fn val -> 
          case val do
          "_" -> # valeur à estimer
            case collector.unite do
            :pourcent -> "#{100 - collector.total}%"
            _ -> "#{800 - collector.total}px"
            end
          _ -> # valeur autre
            val
          end
        end)
        # |> IO.inspect(label: "/nValeurs calculées")
      Map.merge(options, %{
        define_cols: true,
        cols_width: final_cols_width,
        cols_flex:  collector.flex_value
      })
    end # fin de if cols_width

    options = 
    if Enum.any?(options.cols_class) do
      %{ options | define_cols: true }
    else
      options
    end

    options = 
    if Enum.any?(options.cols_align) do
      %{ options | define_cols: true}
    else
      options
    end

    if Enum.any?(options.cols_pad) do
      IO.puts "Il faut définir le padding des colonnes"
    end

    IO.inspect(options, label: "\nOPTIONS après transformations")
    
    # On met les nouvelles options dans le conteneur
    conteneur = %{conteneur | options: options }
    # |> IO.inspect(label: "\nTABLE À CONSTRUIRE")

    conteneur = define_conteneur_header_and_footer(conteneur)
    get_structure_section(conteneur, "table")
  end

  #
  # === TRAITEMENT D'UN CONTENEUR QCM ===
  #

  def to_html(%ExoConteneur{type: :qcm} = conteneur) do

    conteneur =
      if Enum.member?(conteneur.options.extra_options, :permettre_ne_sait_pas) do
        %{conteneur | lines: add_case_ne_sait_pas(conteneur.lines)}
      else conteneur end

    # Il faut définir le type (radio ou checkbox) de chaque question
    # Ce type dépend de la seconde lettre de la question qui précède.
    # Il suffit donc de parcourir les lines, de prendre le type quand
    # on rencontre une question, et de gjl'affecter aux questions qui
    # suivent.
    # On profite de ce premier "tour" sur les lignes pour supprimer les
    # lignes vides qui séparent, dans le texte, les questions
    collector = 
      conteneur.lines
      |> Enum.reject(fn line -> String.trim(line.content) == "" end)
      |> Enum.reduce(%{type_courant: nil, lines: []}, fn line, collector ->
          if String.at(line.tline, 0) == "q" do
            # Pour une question
            qtype = (String.at(line.tline, 1) == "r") && "radio" || "checkbox"
            line = %{ line | classes: [qtype] }
            Map.merge(collector, %{
              type_courant: qtype,
              lines: collector.lines ++ [line]
            })
          else
            # Pour une réponse
            # (on récupère son nombre de points — note : ce nombre
            #  de points jouera aussi sur l'apparence de la réponse
            #  lorsqu'il faudra la montrer :
            #   à 0, la réponse est laissée telle quelle
            #   de 1 à 5, elle est marquée de plus en plus juste
            #   de 6 à 9, elle reste sur très juste — vert foncé
            points = line.tline |> String.at(1) |> StringTo.value()
            new_line = Map.merge(line, %{
              classes: (line.classes || []) ++ [collector.type_courant],
              data:     %{points: points || 0}
            })
            %{ collector | lines: collector.lines ++ [new_line]}
          end
        end)
    new_lines = collector.lines
    
    # IO.inspect(new_lines, label: "\nNew_lines à la fin")

    conteneur = %{conteneur | lines: new_lines}
    get_structure_section(conteneur, "section")
  end

  #
  # CONTENEUR LISTE
  #
  def to_html(%ExoConteneur{type: :liste} = conteneur) do
    get_structure_section(conteneur, "ul")
  end

  #
  # TRAITEMENT DES AUTRES TYPES DE CONTENEUR
  #
  def to_html(conteneur) do
    get_structure_section(conteneur, "section")
  end



  # Pour un QCM avec l'option "permet_ne_sait_pas", on doit ajouter
  # automatiquement la case "Je ne sais pas"
  defp add_case_ne_sait_pas(lines) do
    # Il faut ajouter la case "Je ne sais pas" à toutes les 
    # questions.
    case_dont_know = %ExoLine{
      content: "Je ne sais pas",
      tline: "r1"
    }

    collector = 
    Enum.reduce(lines, %{lines: [], last_is_question: nil}, fn line, coll -> 
      
      safe_car1_tline = String.at((line.tline || "X"), 0)

      is_question = safe_car1_tline == "q"
      question_en_cours = coll.last_is_question == true
      line_is_quest_or_rep = Enum.member?(["q","r"], safe_car1_tline)

      out_of_qcm = question_en_cours && (is_nil(line.tline) || not(line_is_quest_or_rep || is_question))
      
      # On doit ajouter la case "Je ne sais pas" si
      #   - la ligne courante est une question et qu'il y avait une
      #     question en cours
      #   - la ligne courante fait sortir du questionnaire
      new_lines =  
      cond do
        (is_question && question_en_cours) or out_of_qcm  ->
          coll.lines ++ [case_dont_know]
        true -> coll.lines 
      end
      
      coll =
        cond do
          is_question -> %{coll | last_is_question: true}
          out_of_qcm  -> %{coll | last_is_question: false}
          true        -> coll 
        end
      
      # On ajoute toujours la ligne courante
      %{coll | lines: new_lines ++ [line]}
      end)

    # On en ajoute une toute dernière à la toute fin (mais seulement si on
    # est encore dans un questionnaire)
    lines_at_the_end = 
      if (collector.last_is_question == true) do
        # Si c'est une réponse sur une ligne horizontale (classes 
        # contient 'horizontal'), il faut l'ajouter à la case don't
        # know
        # TODO: MALHEUREUSEMENT, ça n'ajoute la propriété "horizontal" que
        # si c'est la dernière ligne. Pour le moment, on joue sur les classes
        # CSS .horizontal + .reponse pour traiter l'alignement.
        classes_last_line = Enum.at(collector.lines, -1).classes
        choix_dont_know =
          if classes_last_line && Enum.member?(classes_last_line, "horizontal") do
            %{case_dont_know | classes: ["horizontal"]}
          else case_dont_know end
        collector.lines ++ [choix_dont_know]
      else collector.lines end

    lines_at_the_end
    # |> IO.inspect(label: "\nLignes remontées")
  end

  # Construction des header/footer pour un conteneur TABLE
  defp define_conteneur_header_and_footer(%ExoConteneur{type: :table} = conteneur) do
    new_options = conteneur.options

    # On définit les colonnes
    new_options = 
    if new_options.define_cols do
      first_line = 
      conteneur.lines
      |> Enum.at(0)
      nombre_colonnes = 
        first_line.content
        |> StringTo.list()
        |> Enum.count
      
      new_options = %{new_options | cols_count: nombre_colonnes}
      colgroup = "<colgroup>"
      <> build_col_in_colgroup(new_options, nombre_colonnes).cols
      <> "</colgroup>"

      %{new_options | section_header: colgroup}
    else
      new_options
    end


    %{conteneur | options: new_options}
  end
  # L'autre type de conteneur : section
  defp define_conteneur_header_and_footer(conteneur), do: conteneur
  
  # Construction (récursive) des <col> de <colgroup>
  defp build_col_in_colgroup(options, reste) when reste > 0 do
    icol = options.cols_count - reste

    styles = []

    styles =
      case Enum.at(options.cols_align, icol) do
        nil -> styles
        col_attr -> styles ++ ["text-align: #{col_attr};"]
        end

    styles = 
      case Enum.at(options.cols_width, icol) do
      nil -> styles
      col_attr -> styles ++ ["width:#{col_attr};"]
      end

    styles =
      if Enum.any?(styles) do
        " style=\"#{Enum.join(styles)}\""
      else "" end
    
    col_class =
      case Enum.at(options.cols_class, icol) do
      nil -> ""
      col_class -> " class=\"#{col_class}\""
      end
    
    col = "<col#{col_class}#{styles} />"
    options = %{ options | cols: options.cols <> col }
    build_col_in_colgroup(options, reste - 1)
  end
  defp build_col_in_colgroup(options, 0), do: options



  defp get_structure_section(conteneur, main_tag) do
    flex = conteneur.options.cols_flex # table à colonne variable

    # Classes css pour le conteneur
    css = ExoConteneur.classes_css(conteneur)

    "<#{main_tag} class=\"#{css}\" style=\"#{if flex, do: "width:100%;"}\">"
    <> conteneur.options.section_header
    <> (conteneur.lines
        |> Enum.map(&ExoInnerFormater.build_element(&1, conteneur))
        |> Enum.join(""))
    <> conteneur.options.section_footer
    <> "</#{main_tag}>"
  end
end # /module ExoConteneur.Builder