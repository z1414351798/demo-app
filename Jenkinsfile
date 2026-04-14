pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        timestamps()
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

                            # 1. Setup local config
                            export KANIKO_HOME="$WORKSPACE/kaniko_home"
                            mkdir -p "$KANIKO_HOME/.docker"
                            export DOCKER_CONFIG="$KANIKO_HOME/.docker"

                            # 2. Create Docker Authentication
                            AUTH=$(echo -n "${DOCKER_USER}:${DOCKER_PASS}" | base64 | tr -d '\\n')
                            echo "{\\"auths\\":{\\"https://index.docker.io/v1/\\":{\\"auth\\":\\"$AUTH\\"}}}" > "$DOCKER_CONFIG/config.json"

                            # 3. RUN KANIKO WITH SUDO
                            # You MUST use sudo here because Kaniko needs to unpack the
                            # base image into the container's root filesystem.
                            sudo /usr/local/bin/kaniko \
                              --force \
                              --context "$WORKSPACE" \
                              --dockerfile "$WORKSPACE/Dockerfile" \
                              --destination "docker.io/$DOCKER_IMAGE:$TAG" \
                              --destination "docker.io/$DOCKER_IMAGE:latest" \
                              --kaniko-dir "$KANIKO_HOME" \
                              --cache=true
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
                    set -eux
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
                    kubectl rollout status deployment/demo-app -n $K8S_NAMESPACE --timeout=180s
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