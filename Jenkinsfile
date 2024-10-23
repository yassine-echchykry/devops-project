pipeline {
    agent any
    
    environment {
        REPORT_DIR = "${WORKSPACE}/reports"
        SONARQUBE_URL = "http://localhost:9000"
        SONARQUBE_SCANNER = 'SonarQubeScanner'
        // Add version control for tools
        GITLEAKS_VERSION = 'v8.18.1'
        DEPCHECK_VERSION = '9.0.9'
        ZAP_VERSION = '2.14.0'
        APP_URL = 'http://localhost:8080'
    }
    
    options {
        timeout(time: 1, unit: 'HOURS')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }
    
    stages {
        stage('Prepare Environment') {
            steps {
                script {
                    // Create report directories
                   sh '''
                        # Create main reports directory
                        mkdir -p ${WORKSPACE}/reports
                        
                        # Create subdirectories with proper permissions
                        cd ${WORKSPACE}/reports
                        mkdir -p gitleaks dependency-check zap
                        
                        # Set permissions recursively
                        chmod -R 777 ${WORKSPACE}/reports
                        
                        # List directories to verify creation
                        ls -la ${WORKSPACE}/reports
                    '''
                    
                    // Clone repository
                    git branch: 'main', 
                        url: 'https://github.com/MohamedRach/devops-project',
                        changelog: true
                }
            }
        }
        
        
        stage('Secret Scanning') {
            steps {
                script {
                    try {
                        timeout(time: 5, unit: 'MINUTES') {
                            sh '''
                                # Remove existing container if it exists
                                docker rm -f gitleaks || true
                                
                                # Start Gitleaks scan
                                docker-compose -f docker-compose.tools.yml up gitleaks
                                
                                # Check if report was generated
                                if [ -f reports/gitleaks/report.json ]; then
                                    echo "Gitleaks scan completed successfully"
                                    # Check if any secrets were found
                                    if [ "$(cat reports/gitleaks/report.json | grep -c '"Description":')" -gt 0 ]; then
                                        echo "Potential secrets found!"
                                        exit 1
                                    fi
                                else
                                    echo "Gitleaks scan failed - no report generated"
                                    exit 2
                                fi
                            '''
                        }
                    } catch (Exception e) {
                        unstable('Gitleaks scan found potential secrets or failed')
                    }
                }
            }
        }
        
        stage('Dependency Scanning') {
            steps {
                script {
                    try {
                        sh '''
                            # Remove existing container if it exists
                            docker rm -f dependency-check || true
                            
                            # Run Dependency Check
                            docker-compose -f docker-compose.tools.yml up dependency-check
                        '''
                    } catch (Exception e) {
                        unstable('Dependency check found vulnerabilities or failed')
                    }
                }
            }
        }
        
        stage('Dynamic Application Security Testing') {
            steps {
                script {
                    try {
                        sh '''
                            # Remove existing container if it exists
                            docker rm -f owasp-zap || true
                            
                            # Start ZAP
                            docker-compose -f docker-compose.tools.yml up -d owasp-zap
                            
                            # Wait for ZAP to start
                            sleep 30
                            
                            # Run ZAP scan
                            docker exec owasp-zap zap-baseline.py -t ${APP_URL} -r zap-report.html
                            
                            # Copy report from container
                            docker cp owasp-zap:/zap/wrk/zap-report.html reports/zap/
                        '''
                    } catch (Exception e) {
                        unstable('ZAP scan found vulnerabilities or failed')
                    } finally {
                        sh 'docker-compose stop owasp-zap'
                    }
                }
            }
        }
        
    }
    
    post {
        always {
            // Archive reports
            archiveArtifacts artifacts: 'reports/**/*', 
                          allowEmptyArchive: true,
                          fingerprint: true
            
            // Clean up containers
            sh '''
                docker-compose down -v
                docker system prune -f
            '''
            
            // Send notification
            emailext (
                subject: "Security Scan: ${currentBuild.currentResult} - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    Check console output at ${env.BUILD_URL}
                    Reports are available in build artifacts.
                """,
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }
        
        cleanup {
            cleanWs()
        }
    }
}
