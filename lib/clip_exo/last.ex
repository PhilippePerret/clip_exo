defmodule Last do
  @moduledoc """
  Module permettant de mémoriser les dernières données utilisées
  dans l'application, par exemple le dernier fichier traité, le
  dernier filtre appliqué, etc.
  """

  defstruct [
    "path" => nil , # dernier fichier travaillé (nom sans extension)
    # 
    # Dernier filtre appliqué à un exercice
    "exo_filter" => nil, 

    # --- Laisser en dernier ---
    # C'est une NaiveDateTime
    "modified_at" => nil
  ]

  @doc """
  RETOURNE la dernière valeur de la propriété +prop+ ou la valeur
  par +defautl+
  """
  def get(prop, default \\ nil) do
    Map.fetch!(last_values, prop) || default
  end
  def get(prop, default \\ nil) when is_atom(prop) do
    get(Atom.to_string(prop), default)
  end

  @doc """
  DÉFINIT la valeur de la propriété +prop+ à +valeur+ et retourne
  la valeur de retour OU +valeur+

  @usage

    Last.set("value", :prop[, retour])
    Last.set("value", "prop"[, retour])

  """
  def set(value, prop, retour \\ nil) do
    lasts = struct(last_values(), [prop, value])
    set_last_values(lasts)
    retour || value
  end
  def set(value, prop, retour \\ nil) when is_atom(prop) do
    set(value, Atom.to_string(prop), retour)
  end

  @path_memo_file ".last_values"
  defp last_values, do: Map.merge(%__MODULE__{}, get_last_values())

  defp get_last_values() do
    if File.exists?(@path_memo_file) do
      @path_memo_file |> File.read!() |> Jason.decode!()
    else %{} end
  end

  defp set_last_values(lasts) do
    lasts = %{lasts | "modified_at" => NaiveDateTime.utc_now()}
    values = lasts |> Map.from_struct() |> Jason.encode!()
    File.write(@path_memo_file, values, [:utf8])
  end

end #/module Last