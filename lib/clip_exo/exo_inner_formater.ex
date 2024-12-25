defmodule ExoInnerFormater do
  @moduledoc """

  MODULE PRINCIPAL QUI CONSTRUIT LE CORPS DE L'EXERCICE

  En entrée, on a le code parsé avec ExoParser (donc un 
  "accumulateur") et en sortie un code HTML formaté

  """

  @doc """
  Function principal qui construit l'exercice à partir de la liste 
  d'élément +element+ retourné par l'accumulateur de 
  ExoParser.parse_code

  """
  def build(elements, %ClipExo.Exo{} = exo, options \\ []) do
    elements
    |> Enum.map(&build_element(&1))
    |> Enum.join("")
  end

  @doc """
  Function qui construit l'élément
  """
  def build_element(%ExoConteneur{} = conteneur) do
    "<div>Construction d'un conteneur</div>"
  end
  def build_element(%ExoLine{} = exoline) do
    "<div>Construction d'une exoline</div>"
  end
  def build_element(%ExoLine{} = exoline, %ExoConteneur{} = conteneur) do
    "<div>Construction d'une exoline dans un conteneur</div>"
  end

  def build_element([type: :separator] = element) do
    "<div>Construction d'un séparateur</div>"
  end

  def build_element(element) do

    "<div>Construction d'un élément inconnu</div>"
  end

end