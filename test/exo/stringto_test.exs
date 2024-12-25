defmodule ClipExo.StringToTest do

  use ExUnit.Case
  
  def test_against(fourni, espere) do
    assert espere == StringTo.list(fourni)
  end

  def test_with_list(liste) do
    Enum.each(liste, fn {fourni, espere} ->
      assert espere == StringTo.list(fourni)
    end)
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

    test " \"[1,2,3], liste\" " do
      test_with_list([
        {"[1,2,3], liste", [[1,2,3], "liste"]},
        {"[[1,2,3], liste]", [[1,2,3], "liste"]}
      ])
    end

  end #/describe .list transforme en liste
end