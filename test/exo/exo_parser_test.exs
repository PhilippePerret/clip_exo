defmodule ClipExo.BaseTest do

  use ExUnit.Case

  # alias ClipExo.Exo

  describe "Parseur de body" do

    test "parse une ligne simple (paragraphe régulier)" do
      provided = "Une simple ligne"
      attendu = {:ok, [type: :regular, content: "Une simple ligne", conteneur: nil]}
      obtenu  = ExoParser.parse_line(provided, nil)
      assert attendu == obtenu
    end

    test "une ligne avec simple classe" do
      provided = "rub: Une ligne avec classe 'rub'"
      attendu  = {:ok, [type: :paragraph, content: "Une ligne avec classe 'rub'", classes: ["rub"], conteneur: nil]}
      obtenu   = ExoParser.parse_line(provided, %ExoConteneur{})
      assert attendu == obtenu
    end
    
    test "une ligne avec deux classes css" do
      provided = "rub.sub: Une ligne avec classe 'rub' et 'sub'   "
      attendu  = {:ok, [type: :paragraph, content: "Une ligne avec classe 'rub' et 'sub'", classes: ["rub", "sub"], conteneur: nil]}
      obtenu   = ExoParser.parse_line(provided, %ExoConteneur{})
      assert attendu == obtenu
    end

    test "une ligne définissant un nouveau conteneur" do
      provided = ":blockcode"
      attendu  = {:ok, [type: :conteneur, conteneur: %ExoConteneur{type: :blockcode}]}
      obtenu   = ExoParser.parse_line(provided, %ExoConteneur{})
      assert attendu == obtenu
    end

    test "une ligne définissant un conteneur, mais avec des paramètres" do
      provided = ":blockcode(pour voir)"
      attendu  = {:ok, [type: :conteneur, conteneur: %ExoConteneur{type: :blockcode}, params: "(pour voir)"]}
      obtenu   = ExoParser.parse_line(provided, nil)
      assert attendu == obtenu
    end

    test "une ligne définisssant un conteneur d'un type inexistant" do
      provided = ":badconteneurtype"
      attendu = {:error, "Type de conteneur inconnu : 'badconteneurtype'"}
      obtenu  = ExoParser.parse_line(provided, %ExoConteneur{})
      assert attendu == obtenu
    end

    test "une ligne simple de conteneur avec un conteneur" do
      provided = ": Ligne simple"
      attendu  = {:ok, [conteneur: %ExoConteneur{type: :raw, lines: [[type: :line, content: " Ligne simple"]]}]}
      obtenu   = ExoParser.parse_line(provided, %ExoConteneur{type: :raw})
      assert attendu == obtenu
    end
    
    test "une ligne de conteneur sans conteneur (erreur)" do
      provided = ": Ligne simple"
      attendu  = {:error, "Ligne de conteneur sans conteneur : ': Ligne simple'" }
      obtenu   = ExoParser.parse_line(provided, nil)
      assert attendu == obtenu
    end

    test "une ligne définissant une option de conteneur, sans conteneur (erreur)" do
      provided = "::numerote"
      attendu  = {:error, "Option de conteneur sans conteneur : 'numerote'"}
      obtenu   = ExoParser.parse_line(provided, nil)
      assert attendu == obtenu
    end

    test "une ligne définissant une option de conteneur" do
      provided = "::numerote"
      attendu  = {:ok, [type: :conteneur, conteneur: %ExoConteneur{type: :raw, options: ["numerote"]}]}
      obtenu   = ExoParser.parse_line(provided, %ExoConteneur{type: :raw})
      assert attendu == obtenu
    end

  end
end 