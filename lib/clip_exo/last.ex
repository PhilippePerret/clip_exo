defmodule Last do
  @moduledoc """
  Module permettant de mémoriser les dernières données utilisées
  dans l'application, par exemple le dernier fichier traité, le
  dernier filtre appliqué, etc.
  """

  defstruct [
    path: nil , # dernier fichier travaillé (nom sans extension)
    
    last_paths: [], # les derniers fichiers travaillés

    # Dernier filtre appliqué à un exercice
    exo_filter: nil, 

    # --- Laisser en dernier ---
    # C'est une NaiveDateTime
    modified_at: nil
  ]

  @doc """
  Chemin d'accès fichier qui conserve les dernières valeurs utilisées
  à commencer par le chemin d'accès au dernier fichier.
  """
  @path_memo_file ".last_values"

  @doc """
  RETOURNE la dernière valeur de la propriété +prop+ ou la valeur
  par +defautl+
  """
  def get(prop, default \\ nil) when is_binary(prop) do
    get(String.to_atom(prop), default)
  end
  def get(prop, default) do
    Map.fetch!(last_values(), prop) || default
  end

  @doc """
  DÉFINIT la valeur de la propriété +prop+ à +valeur+ et retourne
  la valeur de retour OU +valeur+

  @usage

    Last.set("value", :prop[, retour])
    Last.set("value", "prop"[, retour])

  """
  def set(%{} = values) do
    current_values = last_values()
    values 
    |> Enum.reduce(current_values, fn {key, val}, acc -> 
      Map.replace(last_values(), key, val)
      end)
    |> set_last_values()
  end
  def set(value, prop, retour \\ nil) when is_binary(prop) do
    set(value, String.to_atom(prop), retour)
  end
  def set(value, prop, retour) do
    lasts = Map.replace(last_values(), prop, value)
    set_last_values(lasts)
    retour || value
  end


  # @retourne les dernières valeurs enregistrées en une structure
  # %Last{}
  defp last_values do
    Map.merge(%__MODULE__{}, get_last_values())
  end

  # Lit les dernières valeurs dans le fichier et les renvoie
  # (clés atomiques)
  defp get_last_values() do
    if File.exists?(@path_memo_file) do
      @path_memo_file |> File.read!() |> Jason.decode!(keys: :atoms)
    else %{} end
  end

  defp set_last_values(lasts) do
    lasts = %{lasts | modified_at: NaiveDateTime.utc_now()}
    values = lasts |> Map.from_struct() |> Jason.encode!()
    File.write(@path_memo_file, values, [:utf8])
  end

end #/module Last