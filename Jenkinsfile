pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "hoyi9749/andy_zeng"
        TAG = "${BUILD_NUMBER}"
    }

    stages {

        // ❗ REMOVE THIS (Jenkins already does checkout automatically)
        // stage('Checkout Code') { ... }

        stage('Build JAR') {
            agent {
                docker {
                    image 'maven:3.9.9-eclipse-temurin-17'
                }
            }
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $DOCKER_IMAGE:$TAG .'
            }
        }

        stage('Login DockerHub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                }
            }
        }

        stage('Push Image') {
            steps {
                sh 'docker push $DOCKER_IMAGE:$TAG'
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh 'kubectl set image deployment/demo-app demo-app=$DOCKER_IMAGE:$TAG'
            }
        }

        stage('Verify Deployment') {
            steps {
                sh 'kubectl rollout status deployment/demo-app'
            }
        }
    }
}