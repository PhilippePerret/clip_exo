defmodule ClipExo.ExoBuilder do

  alias ClipExo.Exo

  @folder_html Path.absname("./_exercices/html")
  IO.inspect(@folder_html, label: "\nDossier html")

  def start_building(file_name) do
    "Début de la construction de l'exercice '#{file_name}'…"
  end

  def start_parse_file(file_name) do
    "Parse du fichier '#{file_name}'…"
  end
  def parse_file(file_name) do
    exo = Exo.parse_file(file_name)
    IO.inspect(exo, label: "\nEXO (in parse_file)")
    exo
  end
  def end_parse_file(exo) do
    "👍 Fin du parsing du fichier '#{exo[:infos][:file_name]}'."
  end

  ################################################################################
  #
  # CONSTRUCTION DU FICHIER DE CARACTÉRISTIQUES 
  #
  ################################################################################

  def start_build_file_specs(_filename) do
    "Début de la construction du fichier caractéristiques"
  end
  def build_file_specs(exo) do
    IO.inspect(exo, label: "\nEXO (in build_file_specs)")
    template_path = Path.absname("./lib/clip_exo/exo_builder_assets/specs_file_template.html.eex")
    assigns = %{exo: exo}
    code = EEx.eval_file(template_path, Enum.into(assigns, []), [])
    |> IO.inspect(label: "Code évalué")

    # Nom de l'exercice
    exo_name = exo[:infos][:name]

    # Dossier de l'exercice
    exo_folder = Path.join([@folder_html, exo_name])

    # Construire le dossier de l'exerice si nécessaire
    if not File.exists?(exo_folder) do
      File.mkdir(exo_folder)
    end

    # Chemin d'accès au fichier des caractéristiques
    exo_file_specs = Path.join([exo_folder, "#{exo_name}-specs.html"])

    # Construire le fichier
    File.write(exo_file_specs, code)

    exo # à la fin
  end
  def end_build_file_specs(_filename) do
    "👍 Fichier des caractéristiques construit avec succès."
  end

end