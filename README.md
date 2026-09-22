# Le Maillage

Espace communautaire pour un réseau de formation à l'IA.

**En ligne :** https://reseau-maillage.vercel.app

## État actuel

**C'est une maquette, pas encore un outil.** La page est statique : ce qu'un
visiteur écrit reste dans son onglet, personne d'autre ne le voit, et tout
disparaît au rechargement. Un bandeau le dit en permanence, pour qu'on ne
puisse pas inviter un groupe par erreur.

L'espace est **vide** : aucun membre, aucun message, aucune ressource, aucune
date. Seules restent les structures — les quatorze régions, les deux profils
(conseillers IA / l'IA dans mon métier), et la salle.

## Le parti pris

Une première version reprenait la logique de Discord : un espace par région,
six salons dans chacun, soit trente-six endroits où une question pouvait se
perdre. Elle reste consultable sous
[`version-salons.html`](https://reseau-maillage.vercel.app/version-salons.html).

La version actuelle tient en trois décisions :

1. **Un seul fil.** Les régions et les profils sont dans le menu de gauche,
   visibles en permanence, mais ce sont des **filtres** : on ne choisit pas où
   écrire avant d'écrire.
2. **Les questions sans réponse remontent**, avec leur ancienneté. C'est la
   dette visible du groupe, et la première chose qu'on voit en arrivant.
3. **Une seule salle** pour se parler, annoncée sur l'accueil dès que
   quelqu'un s'y trouve.

Quatre écrans : Aujourd'hui, Échanges, Ressources, Dates.

## Ce qui manque pour un usage réel

| Brique | Pourquoi | Piste |
|---|---|---|
| Base de données partagée | Sans elle, aucun message n'existe pour les autres | Supabase (tables `membres`, `messages`, `reponses`) |
| Comptes | Savoir qui écrit, et limiter au groupe | Supabase Auth, lien magique par e-mail |
| Transmission de la voix | Le micro est capté, mais rien ne sort de l'appareil | LiveKit, Daily ou Jitsi |
| Stockage de fichiers | Pour que les ressources soient téléchargeables | Supabase Storage |

Le micro et le partage d'écran passent déjà par `getUserMedia` et
`getDisplayMedia` : vumètre, coupure réelle de la piste, barre d'espace en
push-to-talk. C'est la partie locale ; c'est le transport qui manque.

## Développement

Une page, aucune dépendance, aucune étape de build. Un push sur `main` met la
production à jour.
