defmodule ClipExo do
  @moduledoc """
  ClipExo keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @ui_terms %{
    menus: %{
      "manuel"      => "Manuel",      # menu principal
      "forgerie"    => "Forgerie",    # menu principal
      "formatage"   => "Formatage",   # menu principal
    },
    boutons: %{
      "editer"        => "Éditer l’exercice",
      "preformatage"  => "Préformatage d’un nouvel exercice",
      "produire"      => "Produire le fichier de l'exercice"
    }
  }

  def ui_terms() do
    @ui_terms
  end

end
