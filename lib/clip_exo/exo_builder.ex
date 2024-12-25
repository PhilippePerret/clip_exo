defmodule ClipExo.ExoBuilder do

  alias ClipExo.Exo

  def build_exo(%Exo{} = exo) do
    IO.puts "Construction d'un exercice à partir de %Exo{}"
    IO.inspect(exo, label: "\nEXO")
  end

  def build_exo(path) when is_binary(path) do
    IO.puts "Construction d'un exercice quand on fournit le path"
  end

  def build_exo(elements) when is_list(elements) do
    IO.puts "Construction d'un exercice quand on fournit le résultat de ExoParser.parse_code"
  end

  def build_exo(%{errors: errors, elements: elements}) do
    div_errors = Enum.any?(errors) && build_div_errors(errors) || ""

    IO.puts "Construction d'un exercice à partir d'un accumulateur de ExoParser.parse_code"
  end

  def build_exo(foo) do
    raise(ArgumentError, "La méthode build_exo attend un path ou une liste d'éléments (du parseur). Elle a reçu : " <> inspect(foo) <> ".")
  end
  def build_exo(), do: raise(ArgumentError, "La méthode build_exo attend un path ou une liste d'éléments (du parseur)")


  def build_div_errors(errors) do
    "<div class=\"warning\">#{errors}</div>"
  end
  ###################################################################################
  #  FONCTIONS AVANT ExoParser

  alias ClipExo.Exo

  @folder_html Path.absname("./_exercices/html")
  IO.inspect(@folder_html, label: "\nDossier html")

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



  def end_build_file_specs(_filename) do
    "👍 Fichier des caractéristiques construit avec succès."
  end


  ################################################################################
  #
  # CONSTRUCTION DU FICHIER DE L'EXERCICE PROPREMENT DIT 
  #
  ################################################################################

  def start_build_file_exo(file_name) do
    "Construction de l'exercice '#{file_name}'…"
  end

  # Méthode qui construit vraiment l'exercice
  def build_file_exo(exo) do

    code = ClipExoWeb.ExoBuilderView.build_file_exo(exo)

    # Nom de l'exercice
    exo_name = exo[:infos][:name]

    # Construction du dossier de l'exercice
    exo_folder = build_exo_folder_if_required(exo)

    # Chemin d'accès au fichier des caractéristiques
    exo_file_path = Path.join([exo_folder, "#{exo_name}.html"])

    # Construire le fichier
    File.write(exo_file_path, code)

    exo
  end

  def end_build_file_exo(_exo) do
    "👍 Fichier de l'exercice construit avec succès."
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