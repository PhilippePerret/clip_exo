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


  def aide_formatage(assigns) do
    ~H"""
    <h4>Règles</h4>
    <p>– Tout caractère échappé est gardé tel quel.</p>
    <p>– Les exposants se marquent avec « ^ ».</p>
    <p>– Des substitutions sont automatiquement effectuées (guillemets droits, apostrophes, renforcement des insécables par un nowrap)</p>
    
    <h4>Environnements</h4>
    <div><code>:table</code> (une table)</div>
    <div><code>:etapes</code> (des pas numérotés)</div>
    <div><code>:blockcode</code> (un bloc de code numéroté)</div>
    <div><code>:qcm</code> (un QCM…)</div>
    <div><code>:liste</code> (une liste avec des pictos par exemple)</div>
    <div><code>:raw</code> (code brut — ne sera pas modifié)</div>
    
    <h4>Types de paragraphes</h4>
    <p>Ils peuvent se mettre avant le paragraphe avec <code>&lt;class: Paragraphe…</code></p>

    <h4>Étapes avec pictos</h4>
    <p>(à utiliser dans l'environnement d'une liste d'étapes (<code>:etapes</code>)</p>
    <div><code>:souris</code> : une étape à la souris</div>
    <div><code>:clavier</code> : des touches à presser</div>
    <div><code>:clic</code> : un clic de souris</div>
    <div><code>:menu</code> : un menu à activer</div>
    <div><code>:repete</code> : une action à répéter</div>
    <div><code>:coche</code> : une case à cocher</div>
    <div><code>:radio</code> : un bouton radio à activer</div>
    <div><code>:cle</code> : une clé USB à utiliser</div>
    <div><code>:mesure</code> : une mesure à faire</div>

    <h4>Table</h4>
    <p>(à utiliser dans l'environnement <code>:table</code>)</p>
    <p class="italic">Les arguments des options suivantes concernent chacune des colonnes.</p>
    <div><code>::cols_width</code> : largeur colonnes</div>
    <div><code>::cols_align</code> : alignement colonnes</div>
    <div><code>::cols_pad</code> : padding cellules</div>
    <div><code>::cols_class</code> : class colonnes</div>
    <div><code>::cols_libelle</code> : titre colonnes</div>
    <p>Chaque ligne du tableau est amorcée par un « <code>: </code> » (deux points et espace) et les colonnes sont séparées par des virgules.</p>
    <p class="italic">Si des virgules sont nécessaires, on les échappe.</p>
    
    <h4>QCM</h4>
    <p>(à utiliser dans un environnement <code>:qcm</code>)</p>
    <p>On détermine le type de question par <code>:qr </code> (question à boutons radio — choix unique) ou <code>:qc</code> (question à cases à cocher — choix multiples)</p>
    <p>Chaque question est déterminée ensuite par <code>:r&lt;points></code>. Les points vont impérativement de 0 à 9. À partir de 5, les réponses sont considérées comme juste (donc une alternance de 0 et de 5 suffit à distinguer les bonnes réponses des mauvaises).</p>
    <p>Avec l'option <code>::permettre_ne_sait_pas</code>, à chaque question on ajoute une case ou un bouton radio « Je ne sais pas ». Cette réponse vaut toujours 1 point.</p>

    """
  end

end