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
      exo_titre: exo.infos.titre |> String.replace(~r/\\n/, "<br />"),
      inner_formated: exo.body_html
    ]
    render_to_string(__MODULE__, "exo_file.html", assigns)
    # |> IO.inspect(label: "Code retourné par la vue exo_file.html")

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
        %{label: "Compétences", value: exo.infos.competences || ""},
        %{label: "Logiciels", value: exo.infos.logiciels || ""},
        %{label: "", value: ""},
        %{label: "Auteur", value: exo.infos.auteur},
        %{label: "Révisions", value: exo.infos.revisions},
      ],
      exo_titre: exo.infos.titre |> String.replace(~r/\\n/, "<br />")
    ]
    render_to_string(ClipExoWeb.ExoBuilderView, "specs_file.html", assigns)
  end

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