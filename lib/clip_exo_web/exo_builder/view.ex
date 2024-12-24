defmodule ClipExoWeb.ExoBuilderView do
  use Phoenix.View,
    root: "lib/clip_exo_web/exo_builder/templates",
    path: "", # pour rechercher les templates dans :root
    namespace: ClipExoWeb

  use Phoenix.Component

  use ClipExoWeb, :html

  def build_file_specs(exo) do
    # Enum.into(exo, [])
    assigns = [
      infos: [
        %{label: "Référence", value: exo[:infos][:reference]},
        %{label: "Nom", value: exo[:infos][:name]},
        %{label: "Niveau", value: exo[:infos][:niveau]},
        %{label: "Compétences", value: formated_liste_string_to_ul(exo[:infos][:competences])},
        %{label: "Logiciels", value: formated_liste_string_to_ul(exo[:infos][:logiciels])},
        %{label: "", value: ""},
        %{label: "Auteur", value: exo[:infos][:auteur]},
        %{label: "Révision", value: exo[:infos][:revisions]},


      ],
      exo_titre: exo[:infos][:titre] |> String.replace(~r/\\n/, "<br />")
    ]
    render_to_string(ClipExoWeb.ExoBuilderView, "specs_file.html", assigns)
    |> IO.inspect(label: "Code retourné par la vue")
  end

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