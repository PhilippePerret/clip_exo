defmodule ClipExoWeb.AppComponents do

  use Phoenix.Component

  attr :name, :string, required: true
  
  def appform(%{name: "produire"} = assigns) do
    exoform(Map.put(assigns, :route, "/exo/build"))
  end
  
  def appform(%{name: "editer"} = assigns) do
    exoform(Map.put(assigns, :route, "/exo/editer"))
  end
  
  attr :name, :string, required: true
  def exoform(assigns) do
    assigns = Map.merge(assigns, %{
      ui: ClipExo.ui_terms,
      last_exo_file_path: ClipExo.Exo.last_file_path()
    })
    ~H"""
    <form action={@route} method="POST">
      <div>
        <label for="exo_file_path" class="block">
          Chemin d'accès au fichier
          <%= if @last_exo_file_path do %>
            <span class="smaller italic">
              (par défaut, on reprend le dernier :)
            </span>
          <% end %>
        </label>
    
        <input id="exo_file_path" name="exo[file_path]" type="text" style="width:200px;" value={@last_exo_file_path} />
        <button type="submit"><%= @ui.boutons["produire"] %></button>

        <div>
          <input type="checkbox" id="cb-open-folder" name="open_folder" />  <label for="cb-open-folder">Ouvrir le dossier après fabrication</label>
        </div>
    </div>
    </form>
    """
  end
end