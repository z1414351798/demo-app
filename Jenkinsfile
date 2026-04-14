pipeline {
    agent any

    options {
        disableConcurrentBuilds()
    }

    environment {
        DOCKER_IMAGE = "hoyi9749/andy_zeng"
        TAG = "${BUILD_NUMBER}"
        DOCKER_CONFIG = "/kaniko/.docker"
        K8S_NAMESPACE = "default"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git 'https://github.com/z1414351798/demo-app.git'
            }
        }

        stage('Build JAR') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Build & Push Image with Kaniko') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                    set -eux

                    echo "🔍 Verifying Kaniko installation..."
                    which kaniko
                    kaniko version

                    echo "📂 Checking workspace..."
                    ls -lah $WORKSPACE
                    ls -lah $WORKSPACE/Dockerfile

                    echo "🔐 Configuring Docker Hub authentication..."
                    mkdir -p /kaniko/.docker
                    AUTH=$(echo -n "$DOCKER_USER:$DOCKER_PASS" | base64 | tr -d '\\n')

                    cat > /kaniko/.docker/config.json <<EOF
        {
          "auths": {
            "https://index.docker.io/v1/": {
              "auth": "$AUTH"
            }
          }
        }
        EOF

                    echo "🚀 Building and pushing image to Docker Hub..."

                    /usr/local/bin/kaniko \
                      --context "$WORKSPACE" \
                      --dockerfile "$WORKSPACE/Dockerfile" \
                      --destination "$DOCKER_IMAGE:$TAG" \
                      --destination "$DOCKER_IMAGE:latest" \
                      --cache=true \
                      --verbosity=debug
                    '''
                }
            }
        }

        stage('Verify Kubernetes Connection') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh '''
                    export KUBECONFIG=$KUBECONFIG
                    kubectl config get-contexts
                    kubectl config current-context
                    kubectl get nodes
                    '''
                }
            }
        }

        stage('Lint Helm Chart') {
            steps {
                sh 'helm lint ./helm/demo-app'
            }
        }

        stage('Deploy with Helm') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh '''
                    export KUBECONFIG=$KUBECONFIG
                    helm upgrade --install demo-app ./helm/demo-app \
                      --namespace $K8S_NAMESPACE \
                      --create-namespace \
                      --set image.repository=$DOCKER_IMAGE \
                      --set image.tag=$TAG
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh '''
                    export KUBECONFIG=$KUBECONFIG
                    kubectl rollout status deployment/demo-app -n $K8S_NAMESPACE
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment successful: ${DOCKER_IMAGE}:${TAG}"
        }
        failure {
            echo "❌ Deployment failed!"
        }
    }
}