pipeline {
    agent any

    environment {
        // Define any environment variables you need here
        COMPOSE_FILE = 'docker-compose.yml'
    }

    stages {
        stage('Checkout Code') {
            steps {
                // Checkout the repository
                git branch: 'main', url: 'https://github.com/MohamedRach/devops-project'
            }
        }
        stage('OWASP Dependency-Check Vulnerabilities') {
      steps {
        dependencyCheck additionalArguments: ''' 
                    -o './'
                    -s './'
                    -f 'ALL' 
                    --prettyPrint''', odcInstallation: 'OWASP Dependency-Check Vulnerabilities'
        
        dependencyCheckPublisher pattern: 'dependency-check-report.xml'
      }
    }
        stage('Build Docker Images') {
            steps {
                script {
                    // Build the Docker images using docker-compose
                    sh 'docker-compose -f ${COMPOSE_FILE} build'
                }
            }
        }

        stage('Start Services') {
            steps {
                script {
                    // Start the services (app, postgres, nginx) in detached mode
                    sh 'docker-compose -f ${COMPOSE_FILE} up -d'
                }
            }
        }
        

        

    }

}

