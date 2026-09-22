# Le Maillage

Démo d'espace communautaire pour un réseau national de formation à l'IA.

**En ligne :** https://reseau-maillage.vercel.app

## Ce que la démo montre

- **Un espace par région** (Auvergne-Rhône-Alpes, Occitanie, Bretagne, Île-de-France,
  Hauts-de-France) plus un espace national.
- **Deux profils métier** portés à la fois par des salons dédiés (`#conseillers`,
  `#mon-métier`) et par un rôle coloré sur chaque membre : Conseil, Métier, Animation.
- **Salons spécialisés** : `productions` est une bibliothèque de fichiers qui ont déjà
  servi, `agenda` liste les rendez-vous avec leur jauge de places.
- **Salons vocaux** avec micro réel : vumètre, anneau de parole, coupure de la piste,
  push-to-talk sur la barre d'espace, partage d'écran.
- Réactions, fils de réponses, mentions, non-lus par salon et par espace, présence,
  recherche sur l'ensemble du réseau.

## Ce qui est réel et ce qui ne l'est pas

Le micro et le partage d'écran passent par `getUserMedia` et `getDisplayMedia` : le
vumètre suit votre voix et couper le micro coupe réellement la piste. En revanche il
n'y a **aucun serveur de signalisation** derrière cette démo : rien n'est transmis ni
enregistré, et les autres participants d'un salon vocal sont simulés. L'écran le dit.

Membres, messages, productions et événements sont fictifs.

## Développement

Une page, aucune dépendance, aucune étape de build. Ouvrir `index.html` suffit — sauf
pour le micro, que les navigateurs réservent aux origines sécurisées : utiliser l'URL
déployée.

Le déploiement suit ce dépôt : un push sur `main` met la production à jour.
