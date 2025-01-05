defmodule ClipExoWeb.ExoBuilderView do
  use Phoenix.View,
    root: "lib/clip_exo_web/exo_builder/templates",
    path: "", # pour rechercher les templates dans :root
    namespace: ClipExoWeb

  use Phoenix.Component
  use ClipExoWeb, :html

  #########################################
  # Construction du fichier de l'exercice #
  #                                       #
  # (pour le participant ou le formateur) #
  #########################################
  def build_file_exo(exo) do
    assigns = [
      exo: exo,
      document_formateur: exo.formateur,
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
      exo: exo,
      infos: [
        %{label: "Référence", value: exo.infos.reference},
        %{label: "Nom", value: exo.infos.name},
        %{label: "Niveau", value: exo.infos.niveau},
        %{label: "Durée", value: formated_duree(exo.infos.duree)},
        %{label: "Compétences", value: met_en_forme_liste(exo.infos.competences)},
        %{label: "Logiciels", value: met_en_forme_liste(exo.infos.logiciels)},
        %{label: "", value: "", class: "separator"},
        %{label: "Auteur", value: exo.infos.auteur, class: "smaller"},
        %{label: "Créé le", value: exo.infos.created_at, class: "smaller"},
        %{label: "Révisions", value: formated_revisions(exo.infos.revisions), class: "smaller"}
      ],
      exo_titre: exo.infos.titre |> String.replace(~r/\\n/, "<br />")
    ]
    render_to_string(ClipExoWeb.ExoBuilderView, "specs_file.html", assigns)
  end

  def met_en_forme_liste(liste) do
    cond do
    is_nil(liste) -> "---"
    Enum.count(liste) == 1 -> Enum.at(liste, 0)
    true -> (Enum.map(liste, fn x -> "<li>#{x}</li>" end) |> Enum.join(""))
    end
  end

  defp formated_duree(duree_list) when is_list(duree_list) do
    "De #{human_duree_for(Enum.at(duree_list, 0))} à #{human_duree_for(Enum.at(duree_list, 1))}"
  end
  defp formated_duree(duree) when is_binary(duree) do
    formated_duree(StringTo.list(duree))
  end

  # Pour mettre en forme dans l'exercice final
  defp human_duree_for(minutes) do
    case minutes do
    15 -> "un 1/4 d’heure"
    30 -> "une 1/2 heure"
    45 -> "trois 1/4 d’heure"
    60 -> "une heure"
    90 -> "une heure 30"
    "15" -> "un 1/4 d’heure"
    "30" -> "une 1/2 heure"
    "45" -> "trois quart d’heure"
    "60" -> "une heure"
    "90" -> "une heure 30"
    _ -> "#{minutes} minutes"
    end
  end

  defp formated_revisions(nil = revisions) do
    "---"
  end
  defp formated_revisions(revisions) when is_list(revisions) do
    IO.inspect(revisions, label: "\nRÉVISIONS")
    if Enum.empty?(revisions), do: "---", else: Enum.join(revisions, ", ")
  end
  defp formated_revisions(revisions) when is_binary(revisions) do
    formated_revisions(if revisions == "", do: [], else: StringTo.list(revisions))
  end
  

  slot :col, doc: "Columns with column labels" do
    attr :label, :string, required: true, doc: "Column label"
  end
  
  attr :rows, :list, default: []
  
  def table_specs(assigns) do
    ~H"""
    <table class="table_specs">
      <tr :for={row <- @rows} class={row[:class]}>
        <td :for={col <- @col}>{render_slot(col, row)}</td>
      </tr>
    </table>
    """
  end
end