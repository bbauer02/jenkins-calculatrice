pipeline {
    agent any

    triggers {
        // Lancé par le webhook GitHub à chaque push
        githubPush()
    }

    options {
        // Deux pushs rapprochés ne déploient pas en même temps
        disableConcurrentBuilds()
    }

    environment {
        // L'application est publiée sur le port 3000 de l'hôte
        APP_URL = 'http://host.docker.internal:3000'
    }

    stages {
        stage('Tests') {
            steps {
                // Construit uniquement le stage "builder" du Dockerfile, qui exécute "npm test"
                sh 'docker build --target builder -t calculatrice:test .'
            }
        }
        stage('Build') {
            steps {
                sh 'docker compose build'
                // Tag supplémentaire avec le commit : on sait quelle version tourne
                sh "docker tag calculatrice:latest calculatrice:${env.GIT_COMMIT.substring(0, 7)}"
            }
        }
        stage('Déploiement') {
            steps {
                // Recrée le conteneur uniquement si l'image a changé
                sh 'docker compose up -d'
            }
        }
        stage('Smoke test') {
            steps {
                // Attend que l'application réponde (10 essais, 3 s d'intervalle)
                sh 'curl -fsS --retry 10 --retry-connrefused --retry-delay 3 "$APP_URL" | grep -q "Calculatrice"'
            }
        }
    }

    post {
        success {
            echo "Version ${env.GIT_COMMIT.substring(0, 7)} déployée sur le port 3000"
        }
        failure {
            // Aide au diagnostic : dernières lignes de log de l'application
            sh 'docker compose logs --tail=50 || true'
        }
        always {
            // Supprime les images intermédiaires devenues inutiles
            sh 'docker image prune -f || true'
        }
    }
}
