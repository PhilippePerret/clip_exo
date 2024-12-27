defmodule ExoParser do
  @moduledoc """
  Module qui parse le code du fichier de la définition de l'exercice
  .clip.exo

  Produit une liste qui contient des %ExoConteneur, des %ExoLine et 
  des %ExoDelimitor

  %ExoConteneur
    Un conteneur contenant des lines: [%ExoLine]
  %ExoLine
    Des lignes seules n'appartenant à aucun conteneur.
  %ExoDelimitor
    Juste des délimiteurs pour laisser plus d'air lorsque c'est
    nécessaire.

  (ces structures sont définies dans le fichier exo_structures.ex)

  TODO


  """

  def parse_code(code) do
    IO.puts "--> parse_code"
    # pour fermer l'éventuel conteneur courant en fin de parse
    # du fichier
    code = code <> "\n" 

    # Le collector (pour Enum.reduce) qui va accumuler tous les
    # éléments relevés (dans :elements)
    # La difficulté du parse, ici, est qu'il faut mettre certaines
    # lignes (%ExoLine) dans des conteneur (%ExoConteneur) et en
    # laisser d'autres seule.
    collector = %{
      cur_conteneur: nil,   # Pour conserver le conteneur courant
      elements: [],             # Pour mettre les éléments
      errors:   [],             # Pour conserver les erreurs
      num_line: 0               # Pour connaitre le numéro de ligne
    }

    final_collector = 
      code 
      |> String.split("\n")
      |> Enum.reduce(collector, fn line, collector ->

          # On parse la ligne courante
          collector = %{collector | num_line: collector.num_line + 1}
          res = parse_line(line, collector.cur_conteneur)
          # |> IO.inspect(label: "\nRES")

          case res do
          {:ok, res} ->
            # Une ligne parsée avec succès. Soit on l'ajoute telle 
            # quelle dans collector.elements,
            add_line_or_conteneur(res, collector) # => updated_accumulator
          {:error, err_msg} ->
            # Une erreur a été rencontrée au cours du parsing
            err_msg = err_msg <> " [line #{collector.num_line}]"
            %{collector | errors: collector.errors ++ [err_msg]}
          end
        end)
      
    elements_reduits = 
      final_collector.elements
        |> Enum.map(fn element -> 
            cond do
            # %ExoConteneur{} == element -> element
            is_list(element) and (Keyword.get(element, :type) == :separator) -> %ExoSeparator{}
            is_list(element) and Keyword.get(element, :line) -> Keyword.get(element, :line)
            true -> 
              if Map.has_key?(element, :options) do
                # Les conteneurs (element = %{ExoConteneur})
                %{element | options: eval_options(element)}
              else
                element
              end
            end
          end)
    # ---
    
    IO.inspect(elements_reduits, label: "\nELEMENTS")
    IO.puts "<-- parse_code"

    %{
      errors: final_collector.errors,
      elements: elements_reduits
    }
    # |> IO.inspect(label: "\n\nFINAL_ACCUMULATEUR RETOURNÉ PAR PARSE_CODE (pour réduction)")

  end

  # +res+ est le résultat remonté par le parsing (sans le :ok). Il 
  # peut avoir les formes suivantes:
  #   [line: %ExoLine , conteneur: <conteneur courant|nil>]
  #
  # +collector+ est le collecteur qui sera remis à la fin. Cf. dans
  # la fonction précédente.
  #
  # Comme on peut le voir ici, ça n'est pas dans cette méthode que
  # la ligne est ajoutée à son conteneur si elle appartient à un 
  # conteneur. C'est fait déjà lors du parsing.
  #
  defp add_line_or_conteneur(res, collector) do
    res_conteneur = res[:conteneur] # nil | %ExoConteneur
    
    cond do
    res_conteneur == nil and collector.cur_conteneur ->
      # Marque la fin d'un conteneur : il y avait un conteneur
      # courant (collecteur.cur_conteneur)) mais la ligne parsée
      # l'a annulée (ligne vide, ligne sans ":" devant, etc.)
      # Dans ce cas, on met le conteneur dans les éléments du
      # collecteur et on réinitialise le conteneur courant.
      %{
        collector |
        elements: collector.elements ++ [collector.cur_conteneur],
        cur_conteneur: nil
      }
    res_conteneur == nil ->
      # La ligne n'appartient pas à un conteneur, mais il n'y a pas
      # de collecteur courant. Dans ce cas, on ajoute simplement la
      # ligne dans la liste des éléments.
      # Note : ici, +res+ peut être aussi bien un %ExoLine qu'un
      # %ExoConteneur ou un %ExoSeparator (ou autre structure qui
      # pourrait être inventée par la suite).
      %{
        collector |
        elements: collector.elements ++ [res]
      }
    res_conteneur ->
      # La ligne définit (se trouve dans) un conteneur (qui peut être
      # le conteneur collector.cur_conteneur courant — on ne vérifie
      # pas). On le met en conteneur courant (même si c'est déjà lui)
      %{
        collector |
        cur_conteneur: res_conteneur
      }
    end
    # |> IO.inspect(label: "\nACCU ACTUALISÉ")
    # updated_collector
  end


  @doc """
  Entrée principale qui reçoit une ligne du fichier exercice et retourne
  {:ok, content, conteneur} ou {:error, message_erreur} en cas d'erreur

  Il peut y avoir ces types de lignes :

  <Paragraphe>            Un paragraphe quelconque, sans style (class regular)
  rub: Paragraphe         Paragraphe normal avec une class CSS appliquée
  rub.main: Paragraphe    Paragraphe avec deux classe CSS appliquées
  :<conteneur>            Si +conteneur+ est vide, c'est le début d'un nouveau conteneur.
                          On peut trouver les conteneur :raw, :table, :etapes, :blockcode, etc.
  :   Paragraphe          Un paragraphe à mettre dans le conteneur courant. Le conteneur courant
                          doit être défini.
  :=> Paragraphe          Un résultat dans un conteneur :etapes par exemple
  :+  Paragraphe          Une ligne de code à mettre en exergue dans un conteneur de type :blockcode
  
  +conteneur+
    Structure courante (ou nil)
    %ExoConteneur{type: <type>, lines: [%ExoLine(s)], options: %ExoOptionsConteneur}

  """
  @reg_cssed_paragraph ~r/^(?<classes>[a-zA-Z\.0-9_\-]+)\:(?<content>.+)$/
  @reg_exo_line ~r/
  ^ # début
  \: # commence par deux points
  (?:(?<type_line>[a-z0-9]{1,7}|=>|\+)?(?<pre_line>[ \t]+))? # définition de la ligne dans le conteneur p.e. cr
                                                          # et espace entre deux points et contenu ligne
  (?<options>\:)? # une option éventuelle
  (?<type_cont>[a-z]+)? # le type du conteneur ou le début de ligne de conteneur
  (?<rest>.*) # tout ce qui reste
  $ # jusqu'à la fin
  /x
  def parse_line(line, conteneur) do
    # IO.inspect(line, label: "\n-> parse_line (ligne brute parsée)")

    trimed_line = String.trim(line)

    cond do
    line == "" ->
      # La ligne est tout simplement vide => C'est un séparateur
      # qu'on ajoute tel quel dans les éléments. 
      # Note : une ligne vide met fin au conteneur courant.
       {:ok, [type: :separator, conteneur: nil]}

    trimed_line == ":" and conteneur ->
      # La ligne ne contient que ":" en début de ligne. C'est donc
      # une ligne vide dans le conteneur.
      new_exoline = %ExoLine{type: :line, content: " "}
      conteneur = %{conteneur | lines: conteneur.lines ++ [new_exoline]}
      {:ok, [type: :conteneur, conteneur: conteneur]}

    line =~ @reg_cssed_paragraph ->
      # La ligne se présente sous la forme 'class.class: Contenu'.
      # C'est une ligne stylisée avec une ou plusieurs classes CSS
      # Note : cette ligne, hors conteneur, met donc fin au conteneur
      # courant éventuel.
      {:ok, [line: parse_cssed_line_content(line), conteneur: nil]}
    
    true ->
      # Dans tous les autres cas (la pluart des cas, donc), on analy-
      # se la ligne à l'aide de l'expression régulière en capturant
      # les groupes et on l'analyse dans parse_line_captures/3 si des 
      # groupes ont été trouvés
      case Regex.named_captures(@reg_exo_line, line) do
      nil ->
        # L'expression régulière a échoué avec la ligne, c'est donc
        # une ligne simple.
        # Note : elle annule l'éventuel conteneur courant.
        {:ok, [line: %ExoLine{type: :line, content: trimed_line, classes: []}, conteneur: nil]}
      captures ->
        # Des groupes ont été trouvés dans la ligne parsées, on en
        # fait l'étude.
        # Remonte un tuplet de la forme {:ok, [liste]} ou 
        # {:error, "<message d'erreur>"}
        parse_line_captures(captures, conteneur, line)
      end
    end
  end

  # La fonction est appelée avec les captures de groupes effectués
  # avec l'expression régulière de conteneur.
  defp parse_line_captures(%{
    "type_line"     => type_line,
    "pre_line"      => pre_line,
    "options"       => options, # ne contiendra que ":" mais signifiera que +rest+ est l'option
    "type_cont"     => type_cont,
    "rest"          => rest
  }, conteneur, line) do
    cond do
      options != "" -> 
        # Quand la ligne définit une option de conteneur après "::"
        # Note : on accumule telle quelle (string) les options dans 
        # la propriété raw_options du conteneur et elles seront 
        # évaluées à la fin).
        # Retourne une erreur s'il n'y a pas de conteneur courant.
        if conteneur do
          conteneur = %{conteneur | raw_options: Map.get(conteneur, :raw_options) ++ [type_cont <> rest]}
          {:ok, [type: :conteneur, conteneur: conteneur]}
        else
          {:error, "Option de conteneur sans conteneur : '#{type_cont <> rest}'"}
        end
      type_cont != "" and type_line == "" and pre_line == "" ->
        # Définition d'un nouveau conteneur (":<type conteneur>")
        # Note 1 : Ce type de conteneur doit être connu (la liste est
        #          définie dans exo_structure.ex).
        # Note 2 : Il peut définir des paramètres (qui seront évalués 
        #          plus tard)
        if type_conteneur_valid?(type_cont) do
          rest = PPString.nil_if_empty(rest)
          {:ok, [type: :conteneur, conteneur: %ExoConteneur{type: String.to_atom(type_cont)}, params: rest]}
        else
          {:error, "Type de conteneur inconnu : '#{type_cont}'"}
        end
      type_line != "" || rest != "" ->
        # Quand le type de ligne est défini (p.e. "=>" pour "résul-
        # tat") ou qu'il reste du texte dans +rest+, et que l'analyse
        # n'a pas été captée avant, c'est qu'on est en présence d'une
        # ligne dans un conteneur.
        # Note 1 : Produit une erreur s'il n'y a pas de conteneur
        #          courant. Dans le cas contraire, on met la ligne 
        #          directement dans le conteneur
        if conteneur do
          exoline = parse_cssed_line_content(type_cont <> rest)
          tline = PPString.nil_if_empty(type_line, %{trim: true})
          exoline = Map.merge(exoline, %{preline: String.replace(pre_line, "\t", "  "), tline: tline})
          conteneur = %{conteneur | lines: conteneur.lines ++ [exoline]}
          {:ok, [conteneur: conteneur]}
        else
          {:error, "Ligne de conteneur sans conteneur : '#{line}'"}
        end
      true ->
        # Quand toutes les captures ont été faites mais qu'elles sont
        # vides ou qu'il y a une incompatibilité.
        # TODO: Il faudrait peut-être plus analysé ça.
        {:error, "Aucune correspondance => Impossible d'analyse la ligne '#{line}'…"}
    end

  end

  # Traitement d'une ligne de format : 'css.css: Contenu'
  # Note
  # Cette ligne peut se rencontrer sur une ligne ou dans un autre
  # élément comme un conteneur.
  def parse_cssed_line_content(line) do
    case Regex.named_captures(@reg_cssed_paragraph, line) do
    nil -> 
      %ExoLine{type: :line, content: line, classes: nil}
    captures ->
      %{
        "classes" => classes, 
        "content" => content
      } = captures
      %ExoLine{
        type: :line, 
        content: String.trim(content),
        classes: String.split(classes, ".")
        }
    end
  end

  # Return true si le conteneur est connu
  defp type_conteneur_valid?(type_cont) do
    Map.get(ExoConteneur.get_types_conteneur(), String.to_atom(type_cont), false) != false
  end

  # Retourne les éventuelles options, sous forme de liste
  @reg_function_and_parameters ~r/^(?<fun>[a-z_]+)\((?<parameters>(.*))\)$/
  defp eval_options(conteneur) do
    (conteneur.raw_options || [])
    |> Enum.reduce(%ExoOptionsConteneur{}, fn x, coptions -> 
        # Les options peuvent être simple («««no_num»»») ou 
        # complexes «««cols_label(20%, _)
        x = String.trim(x)
        # |> IO.inspect(label: "\nUNE OPTION")
        captures = Regex.named_captures(@reg_function_and_parameters, x)
        # IO.inspect(captures, label: "\nCAPTURES")
        coptions = # collector
          case captures do
          nil ->
            # Option simple ou liste d'options simple (p.e. no_num, no_bg)
            stringify_parameters(x) |> Enum.map(fn x -> 
              opt_name = String.to_atom(x) 
              %{coptions | opt_name => true}
            end)
          _ ->
            # Option complexe
            %{"fun" => fun, "parameters" => parameters} = captures
            values = 
              if parameters == "" do
                []
              else
                stringify_parameters(parameters)
              end
            opt_name = String.to_atom(fun)
            %{coptions | opt_name => values }
        end
        coptions # l'collector
      end)
      # |> IO.inspect(label: "\nOPTIONS APRÈS ÉVALUATION")
  end

  # Dans le code du fichier, les paramètres string ne sont mis entre
  # guillemets que lorsqu'il y a des espaces. Dans le cas contraire, ils
  # sont mis tel quel. Pour pouvoir en faire des paramètres, il faut
  # donc les entourer de guillemets avant de les évaluer
  #
  defp stringify_parameters(params) do
    if Regex.match?(~r/[^0-9]/, params) && not Regex.match?(~r/"/, params) do
      String.split(params, ",") |> Enum.map(fn x -> String.trim(x) end)
    else
      safe_eval("[" <> params <> "]") # => par exemple [12]
    end
  end
  
  # Quand une valeur est donnée en paramètre (par exemple «««mafonction(valeur)»»» ), on
  # doit l'évaluer avec prudence. Si ça produit une erreur, on considère que c'est
  # une valeur string
  defp safe_eval(maybe_string) do
    try do
      elem(Code.eval_string(maybe_string), 0)
    rescue 
      _e -> maybe_string
    end
  end
  # defp safe_eval(maybe_string, bind) do
  #   try do
  #     elem(Code.eval_string(maybe_string, bind), 0)
  #   rescue 
  #     _e -> maybe_string
  #   end
  # end


end # module ExoParser