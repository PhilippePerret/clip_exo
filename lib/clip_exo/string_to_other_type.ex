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
  @reg_atom ~r/^\:[a-z_]+$/
  @reg_instring ~r/^"(.*)"$/
  @reg_integer ~r/^[0-9]+$/
  @reg_float ~r/^[0-9.]+$/
  @reg_const ~r/(true|false|nil)/
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
          x =~ @reg_atom      -> elem(Code.eval_string(x),0)  # :atom
          x =~ @reg_instring  -> elem(Code.eval_string(x),0)  # String
          x =~ @reg_integer   -> String.to_integer(x) # Integer
          x =~ @reg_float     -> String.to_float(x)   # Float
          x =~ @reg_const     -> elem(Code.eval_string(x),0)
          true -> x # comme string
          end
        end)
    end
  end

  # Fait les transformation d'usage dans les strings.
  # à savoir :
  #   les backstick par deux sont remplacés par des <code>
  #   1^er  en exposant
  #   *italique*
  #   **gras**
  #   __souligné__
  #   --barré--
  #   --barré//remplacé--
  #

  # Ne pas oublier de mettre ici tous les "candidats", c'est-à-dire
  # tous les textes qui peuvent déclencher la correction.
  @reg_candidats_html ~r/[\`\*_\-\^]/

  @reg_backsticks ~r/\`(.+)\`/U; @remp_backsticks "<code>\\1</code>"
  @reg_bold_ital ~r/\*\*\*(.+)\*\*\*/U; @remp_bold_ital "<b><em>\\1</em></b>"
  @reg_bold ~r/\*\*(.+)\*\*/U; @remp_bold "<b>\\1</b>"
  @reg_ital ~r/\*([^ ].+)\*/U; @remp_ital "<em>\\1</em>"
  @reg_underscore ~r/__(.+)__/U; @remp_underscore "<u>\\1</u>"
  @reg_substitute ~r/\-\-(.+)\/\/(.+)\-\-/U; @remp_substitute "<del>\\1</del> <ins>\\2</ins>"
  @reg_strike ~r/\-\-(.+)\-\-/U; @remp_strike "<del>\\1</del>"
  @reg_exposant ~r/\^(.+)(\W|$)/U; @remp_exposant "<sup>\\1</sup>\\2"

  def html(str, _options \\ %{}) do
    # Il faut que le string contienne un "candidat" pour que
    # la correction soit amorcée.
    if Regex.match?(@reg_candidats_html, str) do
      str
      |> String.replace(@reg_backsticks, @remp_backsticks)
      |> String.replace(@reg_bold_ital, @remp_bold_ital)
      |> String.replace(@reg_bold, @remp_bold)
      |> String.replace(@reg_ital, @remp_ital)
      |> String.replace(@reg_underscore, @remp_underscore)
      |> String.replace(@reg_substitute, @remp_substitute)
      |> String.replace(@reg_strike, @remp_strike)
      |> String.replace(@reg_exposant, @remp_exposant)

    else
      str
    end
  end
end