pipeline {
    agent any
    
    environment {
        DOCKER_HUB_CREDS = credentials('dockerhub-creds')
        DOCKER_IMAGE = 'sristi1/polyglot-sandbox'
        EC2_IP = '35.154.206.217'
        SONAR_TOKEN = 'af3dadecabad93d73742b78f437a2c47c7133733'
        NEXUS_URL = 'http://35.154.206.217:8081'
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'master',
                    url: 'https://github.com/Sristi1123/polyglot-sandbox.git'
            }
        }
        
        stage('Install Dependencies') {
            steps {
                sh '''
                    
                    npm install --registry https://registry.npmjs.org
                '''
            }
        }
        
        stage('Build') {
            steps {
                sh 'npx tsc'
            }
        }
        
        stage('SonarQube Scan') {
            steps {
                sh '''
                    npx sonar-scanner \
                        -Dsonar.projectKey=Sristi1123_polyglot-sandbox \
                        -Dsonar.organization=sristi1123 \
                        -Dsonar.host.url=https://sonarcloud.io \
                        -Dsonar.token=${SONAR_TOKEN}
                '''
            }
        }
        
        stage('Quality Gate') {
            steps {
                echo 'Quality Gate skipped - no gate assigned'
            }
        }
        
        stage('Docker Build & Push') {
            steps {
                sh '''
                    docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} .
                    docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${DOCKER_IMAGE}:latest
                    echo ${DOCKER_HUB_CREDS_PSW} | docker login -u ${DOCKER_HUB_CREDS_USR} --password-stdin
                    docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}
                    docker push ${DOCKER_IMAGE}:latest
                '''
            }
        }
        
        stage('Deploy to AWS') {
            steps {
                sh '''
                    ssh -i ~/.ssh/polyglot-key.pem -o StrictHostKeyChecking=no ubuntu@${EC2_IP} "
                        docker pull ${DOCKER_IMAGE}:latest
                        docker stop polyglot-sandbox || true
                        docker rm polyglot-sandbox || true
                        docker run -d --name polyglot-sandbox \
                            -p 3000:3000 \
                            ${DOCKER_IMAGE}:latest
                    "
                '''
            }
        }
        
        stage('Publish to Nexus') {
            steps {
                sh '''
                    npm pack
                    curl -u admin:admin123 \
                        --upload-file *.tgz \
                        ${NEXUS_URL}/repository/npm-hosted/
                '''
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
