defmodule ClipExo.ExoBuilder do

  # alias ClipExo.Exo

  @folder_html_relative "./_exercices/html"
  @folder_html Path.absname(@folder_html_relative)
  # IO.inspect(@folder_html, label: "\nDossier html")


  ################################################################################
  #
  # CONSTRUCTION DU FICHIER DE CARACTÉRISTIQUES 
  #
  ################################################################################


  def build_file_specs(exo) do
    IO.puts "--> build_file_specs"
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

    IO.puts "<-- build_file_specs"
    {:ok, exo} # à la fin
  end

  ################################################################################
  #
  # CONSTRUCTION DU FICHIER DE L'EXERCICE PROPREMENT DIT 
  #
  ################################################################################

  # Méthode qui construit l'exercice proprement dit
  def build_file_exo(exo) do
    IO.puts "--> build_file_exo"

    # Parser le body de l'exo
    collector = ExoParser.parse_code(exo.body)
    # |> IO.inspect(label: "\nCOLLECTEUR")

    inner = [] 
    
    inner = inner ++ [
      if Enum.any?(collector.errors) do
        build_section_errors(collector.errors)
      else
        ""
      end
    ]

    # Le corps de l'exercice
    inner = inner ++ [ExoInnerFormater.build(collector.elements, exo)]

    exo = %{exo | body_html: Enum.join(inner, "")}

    code = ClipExoWeb.ExoBuilderView.build_file_exo(exo)

    # Construction du dossier de l'exercice
    _exo_folder = build_exo_folder_if_required(exo)

    # Chemin d'accès au fichier des caractéristiques
    exo_file_path = exo_html_file(exo)

    # Construire le fichier
    File.write(exo_file_path, code)

    IO.puts "<-- build_file_exo"

    {:ok, exo}
  end

  def build_section_errors(errors) do
    "<pre class=\"warning\">#{Enum.join(errors, "\n")}</pre>"
  end
  
  ################################################################################
  #
  # COPY DES FICHIERS REQUIS DANS LE DOSSIER DE L'EXERCICE
  #
  ################################################################################

  @doc """
  Liste des fichiers requis

  Si la propriété exo.infos.css_files est définie, c'est un fichier styles
  à ajouter à l'exercice. Cf. copy_required_files/1
  """
  @liste_required_files [
    "./_exercices/css/clip_exo.css",
    "./_exercices/images/Icones-actions-sprite.png",
    "./_exercices/images/logo-clip-alpha.png"
  ]

  @doc """
  Copie des fichiers requis dans le dossier de l'exercice.

  Les exercices (dossier) sont pensés pour être totalement autonomes
  c'est-à-dire pour être transmis "as-is" et fonctionner. Pour cela,
  (et aussi pour simplifier les problèmes de path), on copie toujours
  les fichiers requis dans le dossier de l'exercice créé.
  """
  def copy_required_files(exo) do
    IO.puts "--> copy_required_files"
    # Peut-être des fichiers propres à l'exercice
    customs_files = if exo.infos.css_files, do: exo.infos.css_files, else: []
    # Boucle sur tous les fichiers à donner
    @liste_required_files ++ customs_files
    |> Enum.map(fn original -> 
        file_in_exo = Path.join([exo.infos.htm_folder, "z_" <> Path.basename(original)])
        # Le fichier existe-t-il déjà ?
        # Si c'est le cas, on compare sa date de fabrication avec
        # la date de modification du fichier original poru savoir
        # s'il est nécessaire de l'actualiser
        if File.exists?(file_in_exo) do
          if File.stat!(file_in_exo).mtime < File.stat!(original).mtime do
            File.rm(file_in_exo)
          end
        end
        if not File.exists?(file_in_exo) do
          File.cp!(original, file_in_exo) # => :ok ou raise
        end
      end)
      IO.puts "<-- copy_required_files"
      {:ok, exo}
  end


  ################################################################################
  #
  # FONCTIONS GÉNÉRALISTES
  #
  ################################################################################

  # Retourne le chemin d'accès au fichier html de l'exercice
  def exo_html_file(exo) do
    Path.join([exo_html_folder(exo), exo_html_file_name(exo)])
  end

  def exo_html_file(exo, :relative) do
    Path.join([@folder_html_relative, exo.infos.name, exo_html_file_name(exo)])
  end

  def exo_html_file_name(exo) do
    "#{exo.infos.name}.html"
  end
  
  defp build_exo_folder_if_required(exo) do
    exo_folder = exo_html_folder(exo)
    if not File.exists?(exo_folder) do
      File.mkdir(exo_folder)
    end
    exo_folder
  end

  def exo_html_folder(exo) do
    Path.join([@folder_html, exo.infos.name])
  end

end