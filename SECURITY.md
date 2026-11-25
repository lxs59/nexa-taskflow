# Politique de sécurité – TaskFlow

## Signalement des vulnérabilités

Les vulnérabilités doivent être signalées de manière confidentielle au responsable du projet.

## Analyse de sécurité

Le projet utilise les outils suivants :

- Semgrep : analyse statique du code.
- Gitleaks : détection des secrets.
- Trivy : analyse des dépendances et des images Docker.

## Gestion des vulnérabilités

- Les vulnérabilités HIGH et CRITICAL sont prioritaires.
- Les dépendances vulnérables doivent être mises à jour.
- Les images Docker doivent être durcies.
- Les exceptions doivent être documentées et justifiées dans le fichier `.trivyignore`.

## Quality Gate

L'objectif est de bloquer la fusion du code lorsque des vulnérabilités HIGH ou CRITICAL sont détectées par Trivy.

## Gestion des secrets

Aucun secret ne doit être stocké directement dans le code source. Les informations sensibles doivent être transmises par des variables d'environnement.

## Délais de correction

- CRITICAL : 24 heures.
- HIGH : 7 jours.
- MEDIUM : 30 jours.
- LOW : 90 jours.

Le mainteneur de TaskFlow est responsable des corrections.
Les exceptions doivent être datées, justifiées et réévaluées.