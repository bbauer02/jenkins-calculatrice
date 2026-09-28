# ---------- Étape 1 : build + tests ----------
# Image Node.js officielle (version LTS) comme base
FROM node:22-alpine AS builder

# Définir le répertoire de travail dans le conteneur
WORKDIR /app

# Copier d'abord les fichiers de dépendances (meilleure utilisation du cache Docker)
COPY package*.json ./

# Installer toutes les dépendances (incluant devDependencies pour les tests)
RUN npm ci

# Copier tous les fichiers sources
COPY . .

# Exécuter les tests : si un test échoue, la construction de l'image échoue
RUN npm test

# ---------- Étape 2 : image de production ----------
FROM node:22-alpine

# Définir le répertoire de travail
WORKDIR /app

# Copier package.json et package-lock.json
COPY package*.json ./

# Installer uniquement les dépendances de production
RUN npm ci --omit=dev && npm cache clean --force

# Copier le code de l'application depuis le stage builder
COPY --from=builder /app/server.js ./
COPY --from=builder /app/src ./src
COPY --from=builder /app/public ./public

# Utiliser un utilisateur non-root pour des raisons de sécurité
# (l'image officielle node fournit déjà l'utilisateur "node")
USER node

# Documenter le port sur lequel l'application écoute
EXPOSE 3000

# Définir la commande de démarrage
CMD ["node", "server.js"]
