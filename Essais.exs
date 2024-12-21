defmodule ClipExo.Essai do

  
  def run(phrase) do
    reg = ~r/
    ^
    (?:
      (?<tag>[^\(\:)]*)
      (\((?<params>.*)\))?
      :
    )?
    (?<content>.*)
    $
    /xm
    Regex.named_captures(reg, phrase)
    |> rationnalise_captures_line_body()
    |> IO.inspect(label: "\nCaptures")
  end
  
  defp rationnalise_captures_line_body(captures) do
    {
      rationnalise_balise_bodyline(captures["tag"]),
      rationnalise_content_bodyline(captures["content"]),
      rationnalise_params_bodyline(captures["params"])
    }
  end
  defp rationnalise_balise_bodyline(tag) do
    case tag do
    "" -> nil
    tag -> tag |> String.trim() |> String.downcase |> String.to_atom()
    end
  end
  defp rationnalise_content_bodyline(content) do
    String.trim(content)
  end
  defp rationnalise_params_bodyline(params) do
    case params do
    "" -> nil
    params -> params 
      |> String.split(",")
      |> Enum.map(fn x -> elem(Code.eval_string(String.trim(x)), 0) end)
      # TODO Ici, on pourrait apporter une protection suplémentaire : dans
      # le cas où un paramètre ne puisse pas être évalué.
    end
  end

end

ClipExo.Essai.run("Une phrase toute simple")
ClipExo.Essai.run("balise:Une phrase avec balise")
ClipExo.Essai.run("balise(\"et\",\"params\",true,12):Une phrase ave balise et paramètres")