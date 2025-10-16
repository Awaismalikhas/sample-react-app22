pipeline {
    agent any 
    
    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'stage', 'prod'], description: 'Select environment to deploy')
    }

    environment {
        IMAGE_NAME     = "react-frontend"
        CONTAINER_NAME = "react-app"
        EC2_USER       = "ubuntu"
    }

    stages { 
        stage('SCM Checkout') {
            steps {
                git branch: 'stagging', url: 'git@github.com:Awaismalikhas/sample-react-app22.git'
            }
        }

        stage('Run SonarQube Analysis') {
            environment {
                scannerHome = tool 'sonarqube'
            }
            steps {
                withSonarQubeEnv(credentialsId: 'jenkins-sonar-token', installationName: 'jenkins-sonar') {
                    sh """
                        ${scannerHome}/bin/sonar-scanner \
                        -Dsonar.projectKey=sample-react-app \
                        -Dsonar.sources=. \
                        -Dsonar.projectName="Sample React App"
                    """
                }
            }
        }

        // stage('Wait for Quality Gate') {
        //     steps {
        //         timeout(time: 1, unit: 'HOURS') {
        //             waitForQualityGate abortPipeline: true
        //         }
        //     }
        // }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${params.ENVIRONMENT} ."
            }
        }

        stage('Terraform Init & Apply') {
            environment {
                AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
                AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
            }
            steps {
                dir('terraform') {
                    sh """
                        terraform init -reconfigure
                        terraform workspace select ${params.ENVIRONMENT} || terraform workspace new ${params.ENVIRONMENT}
                        terraform apply -var-file="${params.ENVIRONMENT}.tfvars" -auto-approve
                    """
                }
            }
        }

        stage('Fetch EC2 Public IP') {
            steps {
                script {
                    dir('terraform') {
                        env.EC2_HOST = sh(script: "terraform output -raw ec2_public_ip", returnStdout: true).trim()
                    }
                    echo "✅ EC2 Public IP for ${params.ENVIRONMENT}: ${env.EC2_HOST}"
                }
            }
        }

        stage('Select SSH Key Based on Environment') {
            steps {
                script {
                    if (params.ENVIRONMENT == 'dev') {
                        env.SSH_KEY = 'ec2-ssh-dev'
                    } else if (params.ENVIRONMENT == 'stage') {
                        env.SSH_KEY = 'ec2-ssh-stage'
                    } else {
                        env.SSH_KEY = 'ec2-ssh-prod'
                    }
                    echo "🔐 Using SSH key credential: ${env.SSH_KEY}"
                }
            }
        }

        stage('Transfer Docker Image') {
            steps {
                sh "docker save -o ${IMAGE_NAME}.tar ${IMAGE_NAME}:${params.ENVIRONMENT}"
                sshagent([env.SSH_KEY]) {
                    sh "scp -o StrictHostKeyChecking=no ${IMAGE_NAME}.tar ${EC2_USER}@${EC2_HOST}:/home/${EC2_USER}/"
                }
            }
        }

        stage('Deploy on EC2') {
            steps {
                sshagent([env.SSH_KEY]) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} '
                      docker load -i /home/${EC2_USER}/${IMAGE_NAME}.tar &&
                      docker stop ${CONTAINER_NAME} || true &&
                      docker rm ${CONTAINER_NAME} || true &&
                      docker run -d -p 3000:3000 --name ${CONTAINER_NAME} ${IMAGE_NAME}:${params.ENVIRONMENT}
                    '
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ React app deployed successfully to ${params.ENVIRONMENT} (${env.EC2_HOST})!"
        }
        failure {
            echo "❌ Deployment failed on ${params.ENVIRONMENT}!"
        }
    }
}
