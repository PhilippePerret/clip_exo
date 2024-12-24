defmodule ExoParser do

  @doc """
  Entrée principale qui reçoit une ligne du fichier exercice et retourne
  {:ok, content, conteneur} ou {:error, message_erreur} en cas d'erreur

  Il peut y avoir ces types de lignes :

  <Paragraphe>            Un paragraphe quelconque, sans style (class regular)
  rub: Paragraphe         Paragraphe normal avec une class CSS appliquée
  rub.main: Paragraphe    Paragraphe avec deux classe CSS appliquées
  :<conteneur>            Si +conteneur+ est vide, c'est le début d'un nouveau conteneur.
                          On peut trouver les conteneur :raw, :table, :steps, :blockcode, etc.
  :   Paragraphe          Un paragraphe à mettre dans le conteneur courant. Le conteneur courant
                          doit être défini.
  :=> Paragraphe          Un résultat dans un conteneur :steps par exemple
  :+  Paragraphe          Une ligne de code à mettre en exergue dans un conteneur de type :blockcode
  
  +conteneur+
    Structure   %ExoConteneur{type: <type>, options: [<options>]}
  """
  @reg_exo_line ~r/
  ^ # début
  (?<amorce>[a-zA-Z\.0-9_\-]+)? # une ou plusieurs classes
  \:
  (?<options>\:)? # éventuellement une option
  (?<type_conteneur>[a-z_]+)? # le type du conteneur
  (?<rest>.*) # tout ce qui reste
  $ # jusqu'à la fin
  /x
  def parse_line(line, conteneur) do
    Regexp(@reg_exo_line, line)
    |> IO.inspect(label: "Line analysée")
  end

end 