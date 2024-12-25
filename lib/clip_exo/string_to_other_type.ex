defmodule StringTo do

  @doc """
  Function qui reçoit un string est retourne une liste

  Le string peut être sous la forme :

    "" ou "  "              => []
    "Un, deux, trois"       => ["Un", "deux", "trois"]
    "Un, 12, true"          => ["Un", 12, true]
    "Un, \"12\", \"true\""  => ["Un", "12", "true"]
    "Un, :atom, "           => ["Un", :atom, ""]
    "[Un, deux, trois]"     => ["Un", "deux", "trois"]
    "[Un, 1.2, false]"      => ["Un", 1.2, false]
    "Avec\, oui, non"       => ["Avec, oui", "non"]
    "[Avec\, oui, non]"     => ["Avec, oui", "non"]
    "[\"Un\", \"deux\"]"    => ["Un", "deux"]

  """
  def list(str) when is_binary(str) do
    if String.trim(str) == "" do
      []
    else
      String.trim(str)
      |> String.replace(~r/^\[(.*)\]$/, "\\1")
      |> String.replace("\\,", "__VIRG__")
      |> String.split(",")
      # - Une liste à partir d'ici -
      |> Enum.map(fn x -> 
          x = x
            |> String.replace("__VIRG__", ",")
            |> String.trim()
          cond do
          x =~ ~r/^\:[a-z_]+$/      -> elem(Code.eval_string(x),0)  # :atom
          x =~ ~r/^"(.*)"$/         -> elem(Code.eval_string(x),0)  # String
          x =~ ~r/^[0-9]+$/         -> String.to_integer(x) # Integer
          x =~ ~r/^[0-9.]+$/        -> String.to_float(x)   # Float
          x =~ ~r/(true|false|nil)/ -> elem(Code.eval_string(x),0)
          true -> x # comme string
          end
        end)
    end
  end

end