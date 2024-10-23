pipeline {
    agent any

    environment {
        REPORT_DIR = "${WORKSPACE}/reports"
        SONARQUBE_URL = "http://localhost:9000"
        SONARQUBE_SCANNER = 'SonarQubeScanner'
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/MohamedRach/devops-project'
            }
        }


        stage('Run Gitleaks') {
            steps {
                script {
                    // Run Gitleaks using the tools-specific docker-compose file
                    sh ''' docker-compose -f docker-compose.tools.yml up -d gitleaks'''
                }
            }
        }

        stage('Run OWASP Dependency-Check') {
            steps {
                script {
                    // Run Dependency-Check using the tools-specific docker-compose file
                    sh 'docker-compose -f docker-compose.tools.yml run dependency-check /usr/share/dependency-check/bin/dependency-check.sh --project myproject --scan /src --format ALL --out /reports'
                }
            }
        }

        stage('Run OWASP ZAP') {
            steps {
                script {
                    // Run ZAP in daemon mode and perform a quick scan using tools-specific docker-compose file
                    sh '''
                    docker-compose -f docker-compose.tools.yml up -d owasp-zap
                    sleep 10
                    docker-compose -f docker-compose.tools.yml exec owasp-zap zap-cli quick-scan --self-contained http://your-application-to-test.com
                    docker-compose -f docker-compose.tools.yml stop owasp-zap
                    '''
                }
            }
        }


    }

    post {
        always {
            archiveArtifacts artifacts: 'reports/**', allowEmptyArchive: true
        }
    }
}

