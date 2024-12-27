defmodule ClipExo.StringToTest do

  use ExUnit.Case
  
  # Pour tester ««« StringTo.html »»»
  # En envoyant :
  #   [
  #     {"fourni", "attendu"},
  #     {"fourni", "attendu"},
  #     etc.
  #   ]
  def test_with_html(liste) do
    Enum.each(liste, fn {fourni, espere} ->
      espere = (espere == "_") && fourni || espere
      obtenu = StringTo.html(fourni)
      assert espere == obtenu, 
        "Transformation StringTo.html a échoué.\nEn fournissant : #{if String.length(fourni) > 30, do: "\n\t"}#{fourni}\non aurait dû obtenir : #{if String.length(espere) > 30, do: "\n\t"}#{espere}\non a obtenu : #{if String.length(obtenu) > 30, do: "\n\t"}#{obtenu}"
    end)
  end

  # Pour tester ««« StringTo.list »»»
  # En envoyant :
  #   [
    #     {"fourni", "attendu"},
    #     {"fourni", "attendu"},
    #     etc.
    #   ]
    def test_with_list(liste) do
      Enum.each(liste, fn {fourni, espere} ->
        assert espere == StringTo.list(fourni)
      end)
    end
    
    def test_against(fourni, espere) do
      assert espere == StringTo.list(fourni)
    end
  

  describe ".list transforme en liste" do

    test " \"\" ou \"     \" " do
      liste = [ {"", []}, {"   ", []} ]
      test_with_list(liste)
    end

    test "\"Un, deux, trois\"" do
      test_against(
        "Un, deux, trois", 
        ["Un", "deux", "trois"])
    end
    
    test " \"[Un, deux, trois]\" " do
      test_against("[Un, deux, trois]", 
      ["Un", "deux", "trois"])
    end

    test " \"Un, 12, true\" " do
      test_with_list([
        {"Un, 12, true"  , ["Un", 12, true]},
        {"[Un, 12, true]", ["Un", 12, true]},
        {"Un, 1.2, nil", ["Un", 1.2, nil]}
      ])
    end

    test " ««« \"Un\", \"deux\" »»»" do
      test_with_list([
        {"\"Un\", \"deux\", \"trois\"", ["Un", "deux", "trois"]},
        {"[\"Un\", \"deux\", \"trois\"]", ["Un", "deux", "trois"]},
      ])
    end

    test " \"Un, :atom\" " do
      test_with_list([
        {"Un, :atom", ["Un", :atom]},
        {"[Un, :atom]", ["Un", :atom]},
      ])
    end

    test " \"Oui\, c'est bon, Non\, tu crois ?\"" do
      test_with_list([
        {"Oui\\, c'est bon, Non\\, tu crois ?", ["Oui, c'est bon", "Non, tu crois ?"]},
        {"[Oui\\, c'est bon, Non\\, tu crois ?]", ["Oui, c'est bon", "Non, tu crois ?"]},
      ])
    end

  end #/describe .list transforme en liste



  describe ".html remplace par des entités html" do

    test "les backsticks" do
      test_with_html([
        {"normal", "_"},
        {"un `code` pour voir", "un <code>code</code> pour voir"},
        {"`un` et `deux`", "<code>un</code> et <code>deux</code>"},
        {"un `backstick seul", "_"}
      ])
    end

    test "les gras" do
      test_with_html([
        {" un truc sans rien", "_"},
        {" un seul **gras**", " un seul <b>gras</b>"},
        {"un **gras** et **autre**", "un <b>gras</b> et <b>autre</b>"},
        {"un **gras** et un *italic*", "un <b>gras</b> et un <em>italic</em>"}
      ])
    end

    test "les italiques" do
      test_with_html([
        {" rien du tout", "_"},
        {"* item de liste", "_"},
        {"* *item* en italique", "* <em>item</em> en italique"},
        {"un *ital* et *autre* pour", "un <em>ital</em> et <em>autre</em> pour"},
        {"un ***gras_italique***", "un <b><em>gras_italique</em></b>"},
      ])
    end

    test "les soulignés" do
      test_with_html([
        {"rien à faire", "_"},
        {"un __simple__ mot", "un <u>simple</u> mot"},
        {"un __mot__ et __deux mots__ pour", "un <u>mot</u> et <u>deux mots</u> pour"},
        {"un **__texte gras souligné__** pour voir", "un <b><u>texte gras souligné</u></b> pour voir"}
      ])
    end
    test "les barrés" do
      test_with_html([
        {"--une phrase barrée-- pour voir", "<del>une phrase barrée</del> pour voir"}
      ])
    end

    test "les barrés insérés" do
      test_with_html([
        {" rien à faire ", "_"},
        {" pas -dans//ce- qu'on cherche", "_"},
        {"un --texte//substitué--", "un <del>texte</del> <ins>substitué</ins>"},
        {"a --b//c-- et puis --d//e--", "a <del>b</del> <ins>c</ins> et puis <del>d</del> <ins>e</ins>"}
      ])
    end

    test "les exposant" do
      test_with_html([
        {"rien à faire", "_"},
        {"2^e", "2<sup>e</sup>"},
        {"Le 2^e!", "Le 2<sup>e</sup>!"},
        {"2^e et 3^e", "2<sup>e</sup> et 3<sup>e</sup>"},
        {"1^er", "1<sup>er</sup>"},
        {"1^er le premier", "1<sup>er</sup> le premier"},
        {"une note^*", "une note<sup>*</sup>"},
        {"une note^* pour voir", "une note<sup>*</sup> pour voir"},
        {"une note chiffrée^12", "une note chiffrée<sup>12</sup>"},
        {"une note chiffrée^12 et reprise", "une note chiffrée<sup>12</sup> et reprise"}
      ])
    end
  end #/describe ".html"
end