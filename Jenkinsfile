pipeline {
    agent any
    environment {
        DOCKER_IMAGE = 'restapiapp'
        AWS_CREDENTIALS_ID = 'aws-credentials'
        EC2_SSH_KEY_ID = 'aws-ssh'
        TERRAFORM_DIR = '.'
        MY_PUBLIC_IP = '93.159.2.113/32'
    }
    stages {
        stage('Checkout SCM') {
            steps {
                git url: 'https://github.com/SkrytyZubr/crud-app-spring-restapi-db.git', branch: 'main'
            }
        }

        stage('Terraform Init'){
            steps {
                script {
                    dir(env.TERRAFORM_DIR) {
                        withCredentials([aws(credentialsId: env.AWS_CREDENTIALS_ID)]) {
                            bat 'terraform init'
                        }
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    dir(env.TERRAFORM_DIR) {
                        withCredentials([aws(credentialsId: env.AWS_CREDENTIALS_ID)]) {
                            bat "terraform plan -var=\"my_ip_address=${env.MY_PUBLIC_IP}\" -var=\"aws_key_pair_name=terraform-crud-app\""
                        }
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    dir(env.TERRAFORM_DIR) {
                        withCredentials([aws(credentialsId: env.AWS_CREDENTIALS_ID)]) {
                            bat "terraform apply -auto-approve -var=\"my_ip_address=${env.MY_PUBLIC_IP}\" -var=\"aws_key_pair_name=terraform-crud-app\""
                        }
                    }
                }
            }
        }

        stage('Get EC2 Public IP') {
            steps {
                script {
                    dir(env.TERRAFORM_DIR) {
                        env.EC2_PUBLIC_IP = bat(returnStdout: true, script: 'terraform output -raw ec2_public_ip').trim()
                        echo "EC2 Public IP: ${env.EC2_PUBLIC_IP}"
                    }
                }
            }
        }

        stage('Deploy application with docker compose') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: env.EC2_SSH_KEY_ID, keyFileVariable: 'SSH_KEY_FILE')]) {
                        bat """
                            ssh -o StrictHostKeyChecking=no -i ${SSH_KEY_FILE} ubuntu@${env.EC2_PUBLIC_IP} <<EOF
                                # move to folder location (np. /home/ubuntu/)
                                cd /home/ubuntu/

                                # clone repo
                                if [ ! -d "crud-app-spring-restapi-db" ]; then
                                    git clone https://github.com/SkrytyZubr/crud-app-spring-restapi-db.git
                                fi

                                # move to cloned repo
                                cd crud-app-spring-restapi-db

                                # run Docker Compose
                                docker-compose up -d --build
                            EOF
                        """
                    }
                }
            }
        }

        stage('Terraform Destroy (Optional)') {
            steps {
                script {
                    input(id: 'destroyConfirm', message: 'Czy na pewno chcesz zniszczyć infrastrukturę AWS?', ok: 'Tak, zniszcz!')

                    dir(env.TERRAFORM_DIR) {
                        withCredentials([aws(credentialsId: env.AWS_CREDENTIALS_ID)]) {
                            bat "terraform destroy -auto-approve -var=\"my_ip_address=${env.MY_PUBLIC_IP}\" -var=\"aws_key_pair_name=terraform-crud-app\""
                        }
                    }
                }
            }
        }
    }
    post {
        always {
            echo "Pipeline finished."
        }
        failure {
            echo "Pipeline failed. Check logs for details."
        }
    }
}
