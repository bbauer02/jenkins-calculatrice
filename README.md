# TP Jenkins — Calculatrice d'Addition

Dépôt support du TP **« Intégration continue avec Jenkins »**.
Il contient une petite application web Node.js (une calculatrice d'additions, avec ses tests Jest)
et tout le nécessaire pour lancer Jenkins avec Docker.

## Démarrer

1. Créez **votre** dépôt à partir de ce template : bouton **Use this template** → **Create a new repository**.
2. Clonez votre dépôt, puis lancez Jenkins :

   ```bash
   cd jenkins
   ./init-env.sh                  # une seule fois : identifiants admin, port, URL
   docker compose up -d --build   # Jenkins sur http://localhost:8080
   ```

3. Suivez le cours, et vérifiez chaque étape avec :

   ```bash
   ./check.sh <numéro d'étape>    # à lancer à la racine du dépôt
   ```

   Sous Windows, lancez les scripts depuis **Git Bash**.

## Contenu

| Chemin | Rôle |
|---|---|
| `server.js`, `src/`, `public/` | L'application (Express, port 3000) |
| `*.test.js` | Tests unitaires et d'API (`npm test`) |
| `jenkins/` | Image Jenkins du TP (version figée, plugins, configuration as code) |
| `check.sh` | Vérification automatique des étapes du TP |

Les fichiers `Dockerfile`, `docker-compose.yaml`, `calculatrice-app.sh` et `Jenkinsfile` sont
**à écrire pendant le TP**.

## Vous êtes bloqué ?

Chaque étape importante a une branche de correction. Pour récupérer les fichiers d'une étape
dans votre dépôt (vos autres fichiers ne sont pas supprimés) :

```bash
git fetch https://github.com/bbauer02/jenkins-calculatrice.git solution-etape-4
git checkout FETCH_HEAD -- .
git commit -m "Reprise à partir de la solution de l'étape 4"
git push
```

| Branche | État à la fin de l'étape |
|---|---|
| `solution-etape-4` | Dockerfile, docker-compose.yaml, calculatrice-app.sh |
| `solution-etape-6` | + Jenkinsfile complet (déclenché par scrutation) |
| `solution-etape-8` | Jenkinsfile déclenché par le webhook GitHub |
| `exercice-debug` | Un Jenkinsfile contenant 3 erreurs, à corriger (exercice) |

## Lancer l'application sans Docker

```bash
npm install
npm test
npm start      # http://localhost:3000
```
