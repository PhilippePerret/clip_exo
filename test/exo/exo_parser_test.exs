defmodule ClipExo.BaseTest do

  use ExUnit.Case

  # alias ClipExo.Exo

  describe "Parseur de ligne" do

    test "une ligne vide est un séparateur" do
      provided = ""
      attendu  = {:ok, [type: :separator, conteneur: nil]}
      obtenu   = ExoParser.parse_line(provided, %ExoConteneur{type: :raw})
      assert attendu == obtenu
    end

    test "une ligne vide annule le conteneur courant" do
      provided = ""
      obtenu   = ExoParser.parse_line(provided, %ExoConteneur{type: :raw})
      conteneur = elem(obtenu, 1)[:conteneur]
      assert conteneur == nil
    end

    test "parse une ligne simple (paragraphe régulier)" do
      provided = "Une simple ligne"
      attendu = {:ok, [line: %ExoLine{type: :paragraph, content: "Une simple ligne", classes: []}, conteneur: nil]}
      obtenu  = ExoParser.parse_line(provided, nil)
      assert attendu == obtenu
    end

    test "une ligne avec simple classe" do
      provided = "rub: Une ligne avec classe 'rub'"
      attendu  = {:ok, [line: %ExoLine{type: :paragraph, content: "Une ligne avec classe 'rub'", classes: ["rub"]}, conteneur: nil]}
      obtenu   = ExoParser.parse_line(provided, %ExoConteneur{})
      assert attendu == obtenu
    end
    
    test "une ligne avec deux classes css" do
      provided = "rub.sub: Une ligne avec classe 'rub' et 'sub'   "
      attendu  = {:ok, [line: %ExoLine{type: :paragraph, content: "Une ligne avec classe 'rub' et 'sub'", classes: ["rub", "sub"]}, conteneur: nil]}
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
      attendu  = {:ok, [conteneur: %ExoConteneur{type: :raw, lines: [%ExoLine{type: :line, content: " Ligne simple"}]}]}
      obtenu   = ExoParser.parse_line(provided, %ExoConteneur{type: :raw})
      assert attendu == obtenu
    end
    
    test "une ligne de conteneur sans conteneur (erreur)" do
      provided = ": Ligne simple"
      attendu  = {:error, "Ligne de conteneur sans conteneur : ': Ligne simple'" }
      obtenu   = ExoParser.parse_line(provided, nil)
      assert attendu == obtenu
    end

    test "une ligne de conteneur avec un type de ligne (tline)" do
      provided = ":+ Ligne de code ajoutée"
      line = %ExoLine{type: :line, content: " Ligne de code ajoutée", tline: "+", classes: nil}
      attendu  = {:ok, [conteneur: %ExoConteneur{type: :blockcode, lines: [line], options: []}]}
      actual   = ExoParser.parse_line(provided, %ExoConteneur{type: :blockcode})
      assert attendu == actual
    end

    test "une ligne de steps de résultat (=>)" do
      provided = ":=> Ligne de résultat"
      line = %ExoLine{type: :line, content: " Ligne de résultat", tline: "=>", classes: nil}
      attendu = {:ok, [conteneur: %ExoConteneur{type: :steps, lines: [line], options: []}]}
      actual  = ExoParser.parse_line(provided, %ExoConteneur{type: :steps, lines: []})
      assert attendu == actual
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

  end # /describe "parseur de ligne"


  describe "Parseur de code" do

    test "Un bloc raw" do
      provided = ":raw\n: Une première ligne\n: Une deuxième ligne\n"
      attendu  = [
        %ExoConteneur{
          type: :raw, 
          options: [],
          lines: [
            %ExoLine{type: :line, content: " Une première ligne", classes: nil},
            %ExoLine{type: :line, content: " Une deuxième ligne", classes: nil},
          ]
        }
      ]
      obtenu = ExoParser.parse_code(provided)
      assert attendu == obtenu
    end

    test "Un bloc blockcode avec des lignes" do
      provided = ":blockcode\n:  Première ligne de code\n:+ deuxième ligne de code\n"
      attendu  = [
        %ExoConteneur{
          type: :blockcode,
          lines: [
            %ExoLine{type: :line, content: "  Première ligne de code", classes: nil},
            %ExoLine{type: :line, content: " deuxième ligne de code", classes: nil, tline: "+"},
          ],
          options: []
        }
      ]
      actual = ExoParser.parse_code(provided)
      assert attendu == actual
    end
  end #/describe "Parseur de code"
end 