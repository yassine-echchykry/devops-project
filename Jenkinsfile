pipeline {
    agent any
    parameters {
        choice(
            choices: ["Baseline", "APIS", "Full"],
            description: 'Type of scan that is going to perform inside the container',
            name: 'SCAN_TYPE'
        )
        string(
            defaultValue: "http://localhost:8080",  // Utilisez l'URL de l'application exposée
            description: 'Target URL to scan',
            name: 'TARGET'
        )
        booleanParam(
            defaultValue: true,
            description: 'Parameter to know if wanna generate report.',
            name: 'GENERATE_REPORT'
        )
    }
    stages {
        stage('Clone GitHub Repository') {
            steps {
                script {
                    echo "Cloning GitHub Repository..."
                    git url: 'https://github.com/MohamedRach/devops-project', branch: 'main'
                }
            }
        }
        stage('Build Docker Images') {
            steps {
                script {
                    echo "Building Docker images using docker-compose..."
                    sh 'docker-compose build'
                }
            }
        }
        stage('Start Services') {
            steps {
                script {
                    echo "Starting services using docker-compose..."
                    sh 'docker-compose up -d'
                }
            }
        }
        stage('List Docker Images') {
            steps {
                script {
                    echo "Listing Docker images..."
                    sh 'docker images --format "{{.Repository}}:{{.Tag}}" > docker-images.txt'
                }
            }
        }
        stage('Scan Docker Images') {
            steps {
                script {
                    def imageName = sh(script: "docker images --format '{{.Repository}}:{{.Tag}}' | head -n 1", returnStdout: true).trim()
                    if (imageName) {
                        echo "Scanning Docker image: ${imageName}"
                        sh "trivy image --output trivy-docker-report.txt --debug ${imageName}"
                    } else {
                        error "No Docker images found to scan."
                    }
                }
            }
        }

        stage('Pipeline Info') {
            steps {
                script {
                    echo "<--Parameter Initialization-->"
                    echo """
                    The current parameters are:
                        Scan Type: ${params.SCAN_TYPE}
                        Target: ${params.TARGET}
                        Generate report: ${params.GENERATE_REPORT}
                    """
                }
            }
        }
        stage('Setting up OWASP ZAP docker container') {
            steps {
                script {
                    echo "Pulling up last OWASP ZAP container --> Start"
                    sh 'docker pull zaproxy/zap-stable'
                    echo "Starting container --> Start"
                    sh 'docker run -dt --network="host" --name owasp zaproxy/zap-stable /bin/bash'
                }
            }
        }
        stage('Prepare wrk directory') {
            when {
                expression {
                    return params.GENERATE_REPORT
                }
            }
            steps {
                script {
                    sh 'docker exec owasp mkdir /zap/wrk'
                }
            }
        }
        stage('Scanning target on owasp container') {
            steps {
                script {
                    def scan_type = params.SCAN_TYPE
                    def target = params.TARGET
                    if (scan_type == "Baseline") {
                        sh "docker exec owasp zap-baseline.py -t ${target} -x report.xml -I"
                    } else if (scan_type == "APIS") {
                        sh "docker exec owasp zap-api-scan.py -t ${target} -x report.xml -I"
                    } else if (scan_type == "Full") {
                        sh "docker exec owasp zap-full-scan.py -t ${target} -I"
                    } else {
                        echo "Invalid scan type."
                    }
                }
            }
        }
        stage('Copy Report to Workspace') {
            steps {
                script {
                    sh 'docker cp owasp:/zap/wrk/report.xml ${WORKSPACE}/report.xml'
                }
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
    }
    post {
        always {
            echo "Removing container"
            sh '''
                docker stop owasp
                docker rm owasp
            '''
            archiveArtifacts artifacts: '*/report.xml, */dependency-check-report.xml, */trivy--report.txt', allowEmptyArchive: true
        }
        success {
            echo "Pipeline completed successfully!"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}
