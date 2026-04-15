pipeline {
    agent {
        kubernetes {
            yaml '''
    apiVersion: v1
    kind: Pod
    spec:
      containers:
      - name: maven
        image: maven:3.9.9-eclipse-temurin-17
        imagePullPolicy: IfNotPresent
        command: ["tail", "-f", "/dev/null"]
        tty: true
        volumeMounts:
          - name: maven-cache
            mountPath: /root/.m2  # This maps to the container's maven home
      - name: deploy-tools
        image: dtzar/helm-kubectl:latest
        imagePullPolicy: IfNotPresent
        command: ["tail", "-f", "/dev/null"]
        tty: true
      - name: kaniko
        image: gcr.io/kaniko-project/executor:debug
        imagePullPolicy: IfNotPresent
        command: ["/busybox/sh", "-c", "tail -f /dev/null"]
        tty: true
        volumeMounts:
          - name: docker-config
            mountPath: /kaniko/.docker
      volumes:
        - name: maven-cache
          hostPath:
            # IMPORTANT: Replace YOUR_NAME with your actual Mac username
            path: /Users/andrea/.m2
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
                    // Batch mode makes the logs much cleaner
                    sh 'mvn clean package -DskipTests --batch-mode'
                }
            }
        }

        stage('Build & Push with Kaniko') {
            steps {
                container('kaniko') {
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
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    container('deploy-tools') {
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
}