defmodule ClipExo.BaseTest do

  use ExUnit.Case

  alias ClipExo.Exo

  describe "Le parseur" do
    test "doit retourner une erreur avec un code mal formaté" do
      code = ""
      actual = Exo.parse_code(code)
      expected = {:error, "Le code est mal formaté."}
      assert elem(actual, 0) == :error
      assert elem(actual, 1) =~ "mal formaté"
    end

    test "doit parser correctement un code bien formaté (même quand il contient des erreurs)" do
      code = """
      ---
      titre: Mon fichier test
      auteur: Philippe PERRET
      : Mauvais
      mauvais:
      ---
      rub:Mission
      C'est la définition de la mission.
      """
      actual = Exo.parse_code(code)

      expected = %{
        infos: %{
          titre: "Mon fichier test",
          auteur: "Philippe PERRET"
          },
        body:  [
          {:rub, "Mission", nil},
          {nil, "C'est la définition de la mission.", nil}
        ]
      }
      assert {:ok, expected} == actual

    end
    
  end # describe "le parseur"

  describe "Analyse de la ligne de body" do
    test "peut séparer les trois éléments (tag, params, content)" do
      line = "lbc(true):Une ligne de bloc code ajoutée"
      actual = Exo.separe_tag_from_content(line)
      expected = {:lbc, "Une ligne de bloc code ajoutée", [true]}
      assert expected == actual
    end
  end
end 