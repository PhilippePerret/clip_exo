defmodule PPString do

  @doc """
  Return nil si +string+ est une chaine vide ou vidish.

  +options+
    :trim     Si true, on retourne la chaine trimée
              Default: nil
  """
  def nil_if_empty(string, options \\ %{}) do
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
  end
end