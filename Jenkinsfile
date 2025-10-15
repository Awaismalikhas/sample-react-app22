pipeline {
    agent any

    environment {
<<<<<<< HEAD
        IMAGE_NAME = "react-frontend-stg"
        CONTAINER_NAME = "react-app-stg"
=======
        IMAGE_NAME = "react-frontend"
        CONTAINER_NAME = "react-app"
>>>>>>> 6cd042b (Update Jenkinsfile)
        EC2_USER = "ubuntu"
        EC2_HOST = "13.250.123.62"
        SSH_KEY = "ec2-ssh-access"  // Jenkins credential ID for private key
    }

    stages {

        stage('Checkout Code') {
            steps {

                git branch: 'stagging', url: 'git@github.com:Awaismalikhas/sample-react-app22.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${IMAGE_NAME}:latest ."
                }
            }
        }

        stage('Save and Transfer Image') {
            steps {
                script {
                    // Save image to tar file
                    sh "docker save -o ${IMAGE_NAME}.tar ${IMAGE_NAME}:latest"

                    // Copy image to EC2 instance using SSH
                    sshagent(['ec2-ssh-access']) {
                        sh """
                        scp -o StrictHostKeyChecking=no ${IMAGE_NAME}.tar ${EC2_USER}@${EC2_HOST}:/home/${EC2_USER}/
                        """
                    }
                }
            }
        }

        stage('Deploy on EC2') {
            steps {
                sshagent(['ec2-ssh-access']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} '
                      docker load -i /home/${EC2_USER}/${IMAGE_NAME}.tar &&
                      docker stop ${CONTAINER_NAME} || true &&
                      docker rm ${CONTAINER_NAME} || true &&
<<<<<<< HEAD
                      docker run -d -p 4000:3000 --name ${CONTAINER_NAME} ${IMAGE_NAME}:latest
=======
                      docker run -d -p 3000:3000 --name ${CONTAINER_NAME} ${IMAGE_NAME}:latest
>>>>>>> 6cd042b (Update Jenkinsfile)
                    '
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ React app deployed successfully from Jenkins image!"
        }
        failure {
            echo "❌ Deployment failed!"
        }
    }
}
