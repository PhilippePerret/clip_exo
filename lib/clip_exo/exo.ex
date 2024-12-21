# Méthodes propres à un exercice
defmodule ClipExo.Exo do

  @doc """
  Méthode qui prend le code +code+, en supposant qu'il est
  au format clip.exo et le transforme en table (liste) façon
  AST pour produire le document HTML.
  """
  def parse(code) do
    code
    |> decompose_header_body()
  end

  @reg_front_matter ~r/^---\n(?<front_matter>.|\n)*\n---\n((?<body>.|\n)*)/Um
  defp decompose_header_body(code) do
    if Regex.match?(@reg_front_matter, code) do
      Regex.
    end
  end


end
