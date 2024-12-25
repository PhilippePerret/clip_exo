defmodule ClipExo.BuilderTest do
  use ExUnit.Case

  alias ClipExo.ExoBuilder, as: Builder

  test "L'appel de build_exo sans arguments génère une erreur" do
    assert_raise ArgumentError, "La méthode build_exo attend un path ou une liste d'éléments (du parseur)", fn ->
      Builder.build_exo
    end
  end

  describe "build_exo avec un mauvais argument" do
    test "quand nil" do
      assert_raise ArgumentError, "La méthode build_exo attend un path ou une liste d'éléments (du parseur). Elle a reçu : nil.", fn ->
        Builder.build_exo(nil)
      end
    end
    test "quand Map" do
      assert_raise ArgumentError, "La méthode build_exo attend un path ou une liste d'éléments (du parseur). Elle a reçu : %{ma: \"Map\"}.", fn ->
        Builder.build_exo(%{ma: "Map"})
      end
    end
  end #/describe build_exo avec mauvais argument

  describe "build_exo avec une liste d'éléments" do
    elements = [
      [errors: []]
    ]
    actual = Builder.build_exo(elements)
    IO.inspect(actual, label: "\nACTUAL")
  end # describe build_exo avec liste d'éléments

  describe "build_exo avec un accumulateur" do
    test "produit l'exercice" do
      accumulator = %{errors: [], elements: []}
      actual = Builder.build_exo(accumulator)
      
    end
  end #/describe build_exo avec accumulateur

end