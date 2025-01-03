defmodule SafeString do

  @doc """
  Retourne l'entier correspondant à la chaine, même 
  lorsqu'elle est vide, dans lequel cas elle renvoie 0 ou la nouvelle
  valeur par défaut.

  Produit une erreur si la chaine ne correspond pas à un entier.
  """
  def to_integer(string, default \\ 0) do
    case nil_if_empty(string, %{trim: true}) do
    nil -> default
    trimed_string -> String.to_integer(trimed_string)
    end
  end

  @doc """
  Return nil si +string+ est une chaine vide ou vidish.

  +options+
    :trim     Si true, on retourne la chaine trimée
              Default: nil
  """
  def nil_if_empty(string, options \\ %{trim: false}) do
    cond do
    is_binary(string) -> 
      trimed_string = String.trim(string)
      if trimed_string == "" do
        nil
      else
        if options.trim do
          trimed_string
        else
          string
        end
      end
    is_nil(string) -> nil
    true -> raise "#{inspect(string)} ne peut pas être envoyé à SafeString.nil_if_empty"
    end
  end

end