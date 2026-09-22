# Le Maillage

Démo d'espace communautaire pour un réseau national de formation à l'IA.

**En ligne :** https://reseau-maillage.vercel.app

## Le parti pris

Une première version reprenait la logique de Discord : un espace par région,
six salons dans chacun, soit trente-six endroits où une question pouvait se
perdre. Pour des artisans, des kinés ou des maraîchers qui ouvrent l'outil
vingt minutes par semaine, c'est un labyrinthe. Elle reste consultable sous
[`version-salons.html`](https://reseau-maillage.vercel.app/version-salons.html)
pour comparer.

La version actuelle tient en trois décisions :

1. **Un seul fil.** La région et le métier sont des filtres, pas des lieux. On
   n'a plus à choisir où écrire avant d'écrire.
2. **Les questions sans réponse remontent**, avec leur ancienneté en toutes
   lettres. C'est la dette visible du groupe, et la première chose qu'on voit
   en arrivant.
3. **Une seule salle vocale**, annoncée sur l'accueil quand quelqu'un s'y
   trouve. Plus de salons vides à explorer pour savoir où sont les gens.

Quatre écrans : Aujourd'hui, Échanges, Ressources, Dates.

## Ce qui est réel, ce qui ne l'est pas

Le micro et le partage d'écran passent par `getUserMedia` et `getDisplayMedia` :
le vumètre suit votre voix, couper le micro coupe réellement la piste, et la
barre d'espace sert de push-to-talk. En revanche il n'y a **aucun serveur** :
rien n'est transmis ni enregistré, et les autres personnes présentes dans la
salle sont simulées. L'écran le dit.

Membres, messages, ressources et dates sont fictifs.

## Développement

Une page, aucune dépendance, aucune étape de build. Ouvrir `index.html` suffit,
sauf pour le micro que les navigateurs réservent aux origines sécurisées :
utiliser l'URL déployée.

Un push sur `main` met la production à jour.
