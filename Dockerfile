# Utiliser une image Node.js officielle comme base
FROM node:18-alpine AS builder

# Définir le répertoire de travail dans le conteneur
WORKDIR /app

# Copier les fichiers de dépendances
COPY package*.json ./

# Installer toutes les dépendances (incluant devDependencies pour les tests)
RUN npm ci

# Copier tous les fichiers sources
COPY . .

# Exécuter les tests (optionnel - peut être commenté si vous préférez)
RUN npm test

# Stage de production
FROM node:18-alpine

# Définir le répertoire de travail
WORKDIR /app

# Copier package.json et package-lock.json
COPY package*.json ./

# Installer uniquement les dépendances de production
RUN npm ci --production && npm cache clean --force

# Copier le code de l'application depuis le stage builder
COPY --from=builder /app/server.js ./
COPY --from=builder /app/src ./src
COPY --from=builder /app/public ./public

# Créer un utilisateur non-root pour des raisons de sécurité
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Changer pour l'utilisateur non-root
USER nodejs

# Exposer le port sur lequel l'application écoute
EXPOSE 3000

# Définir la commande de démarrage
CMD ["node", "server.js"]
