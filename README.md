# ClipExo

Application Phoenix/Elixir pour gérer les exercices du Clip (CLub Informatique en Pénitencier).

## Description

On écrit les fichiers d'exercice dans un format simple, le format "clip-exo" et l'application produit des fichiers HTML et PDF bien mis en forme.

## Exemple

On fournit le fichier :

~~~document
---
name: PSW-00
reference: PSW-00-0
titre: Le Titre de \n l'exercice
niveau: débutant
auteur: Philippe PERRET
creation: 21-12-2024
reviseurs: Philippe PERRET, Marion MICHEL
revisions: 21/12/2024 (Philippe PERRET), 22/12/2024 (Marion MICHEL)
duree: [15,30]
competences: ["Pouvoir faire ça", "Et pouvoir faire ceci"]
---
rub:Mission
La mission de cet exercice consiste à… le réussir !
/rub

rub:Scénario
Suivre simplement ce scénario.
pas: Faire la première action
pas(rouge): Faire la deuxième action
pas: Faire la troisième action
pas(resultat): Ça produit le résultat attendu.

rub:Aide
Si vous voulez de l'aide, faites appel à vos neurones !
~~~

Ce code produit :

{Afficher ici le résultat}

Définition des tables, il faut échapper les virgules (car elles servent de délimiteur de cellule)

- borders(h,v) -- par défaut
  borders(h) -- seulement horizontales
  borders(v) -- seulement verticales
  cols_label(name, name, ... name) -- label pour chaque colonne (th)
  cols_width(widt, width, ... width) -- width pour chaque colonne ("_" pour "ce qui reste")
  cols_pad(x,y,..z) -- padding de chaque colonne

### Styles textes

~~~
`du code inline`
*texte italic*
**texte gras**
__texte souligné__
--texte barré--
--barré//ajouté--
~~~