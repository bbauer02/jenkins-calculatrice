// EXERCICE : ce Jenkinsfile contient 3 erreurs.
// Lancez le pipeline, lisez la sortie de la console, corrigez, poussez… jusqu'au vert.
pipeline {
    agent any

    options {
        disableConcurrentBuilds()
    }

    environment {
        APP_URL = 'http://host.docker.internal:3001'
    }

    stages {
        stage('Tests') {
            steps {
                sh 'docker build --target build -t calculatrice:test .'
            }
        }
        stage('Build') {
            steps {
                sh 'docker compose build'
            }
        }
        stage('Déploiement') {
            steps {
                sh 'docker-compose up -d'
            }
        }
        stage('Smoke test') {
            steps {
                sh 'curl -fsS --retry 5 --retry-connrefused --retry-delay 3 "$APP_URL" | grep -q "Calculatrice"'
            }
        }
    }
}
