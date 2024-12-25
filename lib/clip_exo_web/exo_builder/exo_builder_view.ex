defmodule ClipExoWeb.ExoBuilderView do
  use Phoenix.View,
    root: "lib/clip_exo_web/exo_builder/templates",
    path: "", # pour rechercher les templates dans :root
    namespace: ClipExoWeb

  use Phoenix.Component
  use ClipExoWeb, :html

  #########################################
  # Construction du fichier de l'exercice #
  #########################################
  def build_file_exo(exo) do
    assigns = [
      exo: exo,
      exo_titre: exo[:infos][:titre] |> String.replace(~r/\\n/, "<br />"),
      lines_formated: formate_lines_of_exo(exo)
    ]
    render_to_string(__MODULE__, "exo_file.html", assigns)
    |> IO.inspect(label: "Code retourné par la vue")

  end

  # Méthode principale qui formate les lignes des exercices à partir du 
  # code +exo[:body]+
  @table_short_type_to_full_type %{
    :rub  => "rubrique", 
    :rubi => "rubriquesi",
    nil   => "regular"
  }
  @table_short_param_to_full_param %{
    "+" => "added"
  }
  def formate_lines_of_exo(exo) do
    exo[:body]
    |> Enum.map(fn dline -> 
        {line_type, line_content, line_param} = dline
        line_param =
          cond do
          is_binary(line_param) -> 
            get_real_param(line_param)
          is_list(line_param)   -> 
            line_param |> Enum.map(fn pm -> get_real_param(pm) end) |> Enum.join(" ")
          line_param == nil     -> 
            ""
          end
        
        [line_content, line_type] = 
          if line_content == "" do
            ["&nbsp;", "empty"] 
          else
            [line_content, line_type]
          end

        # Pour certains types de ligne, on doit faire des corrections du texte
        line_content = 
          case line_type do
          :code -> traite_line_type_code(dline)
          _ -> String.trim(line_content)
          end

        css_class = 
          [Map.get(@table_short_type_to_full_type, line_type, line_type), line_param]
          |> Enum.join(" ")
          |> String.trim()
        "<div class=\"#{css_class}\">#{line_content}</div>"
      end)
    |> Enum.join("")
  end

  defp get_real_param(param) do
    Map.get(@table_short_param_to_full_param, param, param)
  end

  defp traite_line_type_code(dline) do
    {_line_type, line_content, _line_param} = dline
    line_content
    |> String.replace("<", "&lt;")
    |> String.replace("\t", "  ")
    |> String.replace([" ", " "], "&nbsp;")
    # |> IO.inspect(label: "\nString de code")
  end
  
  ##############################################################
  # Construction du fichier des caractéristiques de l'exercice #
  ##############################################################
  def build_file_specs(exo) do
    assigns = [
      infos: [
        %{label: "Référence", value: exo.infos.reference},
        %{label: "Nom", value: exo.infos.name},
        %{label: "Niveau", value: exo.infos.niveau},
        %{label: "Compétences", value: formated_liste_string_to_ul(exo.infos.competences)},
        %{label: "Logiciels", value: formated_liste_string_to_ul(exo.infos.logiciels)},
        %{label: "", value: ""},
        %{label: "Auteur", value: exo.infos.auteur},
        %{label: "Révisions", value: exo.infos.revisions},
      ],
      exo_titre: exo.infos.titre |> String.replace(~r/\\n/, "<br />")
    ]
    render_to_string(ClipExoWeb.ExoBuilderView, "specs_file.html", assigns)
    |> IO.inspect(label: "Code retourné par la vue")
  end

  # Reçoit une liste de type «["item 1", "item 2", ... "item N"]» (String) et
  # retourne la liste évaluée ["item 1", "item 2", ... "item N"] (List)
  def formated_liste_string_to_ul(raw_liste) do
    cond do
    nil -> ""
    is_binary(raw_liste) ->
      Code.eval_string(raw_liste)
      |> elem(0)
      |> Enum.map(fn com -> 
        "<li>#{com}</li>"
        end)
      |> Enum.join("")
    true -> raw_liste
    end
  end

  # attr :id, :atom
  # def row_for(assigns) do
  #   ~H"""
  #   <tr>
  #     <td><%= @id %></td>
  #     <td></td>
  #   </tr>
  #   """
  # end

  


  slot :col, doc: "Columns with column labels" do
    attr :label, :string, required: true, doc: "Column label"
  end
  
  attr :rows, :list, default: []
  
  def table_specs(assigns) do
    ~H"""
    <table class="table_specs">
      <tr :for={row <- @rows}>
        <td :for={col <- @col}>{render_slot(col, row)}</td>
      </tr>
    </table>
    """
  end
end