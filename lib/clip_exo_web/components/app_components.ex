defmodule ClipExoWeb.AppComponents do

  use Phoenix.Component


  @ui_boutons ClipExo.ui_terms().boutons


  attr :type, :string, required: true # bout de route
  attr :path, :string, required: true # path de l'exercice
  attr :class, :string, default: "" # class CSS éventuelle
  attr :name, :string, default: nil

  def bouton(assigns) do
    assigns = Map.merge(assigns, %{
      route:  "/exo/#{assigns.type}",
      bouton: assigns.name || @ui_boutons[assigns.type]
    })
    ~H"""
    <form action={@route} method="POST">
      <input type="hidden" name="exo[path]" value={@path} />
      <button type="submit" class={@class}><%= @bouton %></button>
    </form>
    """
  end
end