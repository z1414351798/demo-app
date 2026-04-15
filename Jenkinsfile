pipeline {
    agent {
        kubernetes {
            cloud 'kubernetes'
            yaml '''
            apiVersion: v1
            kind: Pod
            spec:
              containers:
              - name: maven
                image: maven:3.9.9-eclipse-temurin-17
                imagePullPolicy: IfNotPresent  # <--- Add this
                command: ["tail", "-f", "/dev/null"]
                tty: true
              - name: kaniko
                image: gcr.io/kaniko-project/executor:latest
                imagePullPolicy: IfNotPresent  # <--- Add this
                command: ["sleep", "infinity"]
                tty: true
                volumeMounts:
                  - name: docker-config
                    mountPath: /kaniko/.docker
              volumes:
                - name: docker-config
                  secret:
                    secretName: regcred
                    items:
                      - key: .dockerconfigjson
                        path: config.json
            '''
        }
    }

    environment {
        DOCKER_IMAGE = "hoyi9749/andy_zeng"
        TAG = "${BUILD_NUMBER}"
        K8S_NAMESPACE = "default"
    }

    stages {
        stage('Checkout & Build') {
            steps {
                container('maven') {
                    checkout scm
                    sh 'mvn clean package -DskipTests'
                }
            }
        }

        stage('Build & Push with Kaniko') {
            steps {
                container('kaniko') {
                    // Kaniko shares the workspace with the maven container
                    sh '''
                    /kaniko/executor --context `pwd` \
                      --dockerfile `pwd`/Dockerfile \
                      --destination ${DOCKER_IMAGE}:${TAG} \
                      --destination ${DOCKER_IMAGE}:latest
                    '''
                }
            }
        }

        stage('Deploy to K8s') {
            steps {
                // We use the maven container here because it usually has 'sh'
                // but you must ensure helm/kubectl are installed on your Jenkins agent
                // OR add a third container to the Pod for helm
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh '''
                    export KUBECONFIG=$KUBECONFIG
                    helm upgrade --install demo-app ./helm/demo-app \
                      --namespace $K8S_NAMESPACE \
                      --create-namespace \
                      --set image.repository=$DOCKER_IMAGE \
                      --set image.tag=$TAG

                    kubectl rollout status deployment/demo-app -n $K8S_NAMESPACE --timeout=180s
                    '''
                }
            }
        }
    }
}