defmodule ClipExo.ExoBuilder do

  alias ClipExo.Exo

  @folder_html Path.absname("./_exercices/html")
  # IO.inspect(@folder_html, label: "\nDossier html")


  ################################################################################
  #
  # CONSTRUCTION DU FICHIER DE CARACTÉRISTIQUES 
  #
  ################################################################################


  def build_file_specs(exo) do
    # IO.inspect(exo, label: "\nEXO (in build_file_specs)")
    # template_path = Path.absname("./lib/clip_exo/exo_builder_assets/specs_file_template.html.eex")
    # assigns = %{exo: exo}
    # code = EEx.eval_file(template_path, Enum.into(assigns, []), [])
    # |> IO.inspect(label: "Code évalué")

    code = ClipExoWeb.ExoBuilderView.build_file_specs(exo)

    # Nom de l'exercice
    exo_name = exo.infos.name

    # Construire le dossier de l'exerice si nécessaire
    exo_folder = build_exo_folder_if_required(exo)

    # Chemin d'accès au fichier des caractéristiques
    exo_file_specs = Path.join([exo_folder, "#{exo_name}-specs.html"])

    # Construire le fichier
    File.write(exo_file_specs, code)

    {:ok, exo} # à la fin
  end


  ################################################################################
  #
  # CONSTRUCTION DU FICHIER DE L'EXERCICE PROPREMENT DIT 
  #
  ################################################################################

  # Méthode qui construit l'exercice proprement dit
  def build_file_exo(exo) do

    # Parser le body de l'exo
    accumulateur = ExoParser.parse_code(exo.body)
    # |> IO.inspect(label: "\nACCUMULATEUR")

    inner = [] 
    
    inner = inner ++ [
      if Enum.any?(accumulateur.errors) do
        build_section_errors(accumulateur.errors)
      else
        ""
      end
    ]

    # Le corps de l'exercice
    inner = inner ++ [ExoInnerFormater.build(accumulateur.elements, exo)]

    exo = %{exo | body_html: Enum.join(inner, "")}

    code = ClipExoWeb.ExoBuilderView.build_file_exo(exo)

    # Nom de l'exercice
    exo_name = exo.infos.name

    # Construction du dossier de l'exercice
    exo_folder = build_exo_folder_if_required(exo)

    # Chemin d'accès au fichier des caractéristiques
    exo_file_path = Path.join([exo_folder, "#{exo_name}.html"])

    # Construire le fichier
    File.write(exo_file_path, code)

    {:ok, exo}
  end

  def build_section_errors(errors) do
    "<div class=\"warning\">#{errors}</div>"
  end
  
  ################################################################################
  #
  # FONCTIONS GÉNÉRALISTES
  #
  ################################################################################

  defp build_exo_folder_if_required(exo) do
    exo_folder = Path.join([@folder_html, exo.infos.name])
    if not File.exists?(exo_folder) do
      File.mkdir(exo_folder)
    end
    exo_folder
  end

end