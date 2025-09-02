# Calculatrice d'Addition

Une application web simple de calculatrice qui effectue uniquement des additions, développée avec Node.js, Express et une interface graphique moderne.

## 🚀 Fonctionnalités

- ✨ Interface graphique moderne et responsive
- ➕ Calcul d'additions uniquement
- ⌨️ Saisie directe d'expressions (ex: 12 + 34)
- 🖱️ Clavier virtuel cliquable intégré
- 📊 Historique des 10 derniers calculs (cliquables pour réutilisation)
- 🔢 Support des nombres entiers et décimaux
- ✅ Tests unitaires complets avec Jest
- 🎨 Design épuré avec animations fluides
- 🎹 Support complet du clavier physique

## 📋 Prérequis

- Node.js (version 14 ou supérieure)
- npm (gestionnaire de paquets Node.js)

## 🛠️ Installation

### Option 1 : Installation classique

1. Clonez le dépôt ou téléchargez les fichiers du projet

2. Installez les dépendances :
```bash
npm install
```

### Option 2 : Utilisation avec Docker 🐳

1. Assurez-vous d'avoir Docker et Docker Compose installés sur votre machine

2. Construisez et lancez l'application :
```bash
docker-compose up -d
```

Ou avec Docker uniquement :
```bash
# Construire l'image
docker build -t calculatrice-app .

# Lancer le conteneur
docker run -d -p 3000:3000 --name calculatrice calculatrice-app
```

## 🎮 Utilisation

### Démarrer l'application

Pour lancer le serveur en mode production :
```bash
npm start
```

Pour lancer le serveur en mode développement (avec rechargement automatique) :
```bash
npm run dev
```

L'application sera accessible à l'adresse : `http://localhost:3000`

### 🐳 Commandes Docker utiles

```bash
# Voir les logs de l'application
docker-compose logs -f

# Arrêter l'application
docker-compose down

# Reconstruire l'image après modifications
docker-compose up -d --build

# Accéder au conteneur en cours d'exécution
docker exec -it calculatrice-app sh

# Nettoyer les images et conteneurs
docker-compose down --rmi all --volumes

# Voir l'état de santé du conteneur
docker ps
```

### Utiliser la calculatrice

#### Méthode 1 : Saisie au clavier
1. Tapez directement votre expression dans le champ (ex: 25 + 17)
2. Appuyez sur Entrée ou cliquez sur "="
3. Le résultat s'affiche instantanément

#### Méthode 2 : Clavier virtuel
1. Cliquez sur les boutons numériques pour composer votre calcul
2. Utilisez le bouton "+" pour l'addition
3. Cliquez sur "=" pour calculer

#### Raccourcis clavier
- **Chiffres (0-9)** : Ajoute le chiffre
- **+** : Ajoute le signe plus
- **.** : Ajoute un point décimal
- **Entrée ou =** : Calcule le résultat
- **Échap ou C** : Efface tout
- **Retour arrière** : Efface le dernier caractère

#### Historique
- Les 10 derniers calculs sont conservés
- Cliquez sur un calcul dans l'historique pour le réutiliser

### 📸 Aperçu de l'interface
L'interface propose :
- Un champ de saisie unique pour taper directement l'expression (ex: 12 + 34)
- Un clavier virtuel complet avec chiffres, point décimal et opérateur +
- Boutons colorés : 
  - Chiffres en gris clair
  - Opérateur + en bleu
  - Effacer (C) en rouge
  - Retour (←) en orange
  - Égal (=) en violet avec gradient
- Un affichage clair du résultat sous l'expression
- Un historique cliquable des calculs précédents
- Des animations fluides et un design moderne

## 🧪 Tests

### Lancer les tests
```bash
npm test
```

### Lancer les tests en mode watch
```bash
npm run test:watch
```

### Générer un rapport de couverture
```bash
npm run test:coverage
```

## 📁 Structure du projet

```
calculatrice-jenkins/
├── public/              # Fichiers statiques (frontend)
│   ├── index.html      # Page HTML principale
│   ├── styles.css      # Styles CSS
│   └── app.js          # JavaScript côté client
├── src/                 # Code source
│   ├── calculatrice.js  # Module de calcul
│   └── calculatrice.test.js  # Tests du module
├── server.js            # Serveur Express
├── server.test.js       # Tests de l'API
├── package.json         # Configuration npm
├── Dockerfile          # Configuration Docker
├── docker-compose.yml  # Configuration Docker Compose
├── .dockerignore       # Fichiers à ignorer lors du build Docker
└── README.md           # Ce fichier
```

## 🔧 API

### POST /api/addition

Effectue l'addition de deux nombres.

**Corps de la requête :**
```json
{
  "nombre1": 5,
  "nombre2": 3
}
```

**Réponse réussie (200) :**
```json
{
  "resultat": 8
}
```

**Réponse d'erreur (400) :**
```json
{
  "erreur": "Message d'erreur descriptif"
}
```

## 🎨 Technologies utilisées

- **Backend :** Node.js, Express.js
- **Frontend :** HTML5, CSS3, JavaScript vanilla
- **Tests :** Jest, Supertest
- **Design :** Interface moderne avec gradients et animations CSS
- **Conteneurisation :** Docker, Docker Compose

## 📝 Notes

- L'application ne fait que des additions conformément aux spécifications
- Tous les nombres (entiers, décimaux, négatifs) sont supportés
- Les chaînes numériques sont automatiquement converties
- L'historique est stocké uniquement côté client (perdu au rechargement)

## 🤝 Contribution

Ce projet est un exemple simple à des fins éducatives. N'hésitez pas à le forker et à l'améliorer !

## 📄 Licence

Ce projet est sous licence ISC.
