pipeline {
    agent any
    environment {
        DOCKER_IMAGE = 'restapiapp'
        AWS_CREDENTIALS_ID = 'aws-credentials'
        EC2_SSH_KEY_ID = 'aws-ssh'
        MY_PUBLIC_IP = '93.159.2.113/32'

        TERRAFORM_DIR = 'ops-repo' 
        APP_REPO_DIR = 'app-repo'
    }
    stages {
        stage('Checkout OPS SCM') {
            steps {
                dir('ops-repo') {
                    git branch: 'main', url: 'https://github.com/SkrytyZubr/crud-app-spring-restapi-db-ops.git'
                }
            }
        }
    stage('Checkout APP SCM') {
        steps {
            dir(env.APP_REPO_DIR) {
                    git branch: 'main', url: 'https://github.com/SkrytyZubr/crud-app-spring-restapi-db.git'
                }
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
                    dir('ops-repo') {
                        def ec2PublicIp = bat(script: 'terraform output -raw ec2_public_ip', returnStdout: true).trim()
                        env.EC2_PUBLIC_IP = ec2PublicIp
                        echo "Successfully retrieved EC2 Public IP."
                    }
                }
            }
        }

        stage('Deploy application with docker compose') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: env.SSH_CREDENTIALS_ID, keyFileVariable: 'SSH_KEY')]) {
                        echo "Starting application deployment to EC2."

                        dir('ops-repo') {
                            bat "scp -o StrictHostKeyChecking=no -i \"${SSH_KEY}\" docker-compose.yml ubuntu@${env.EC2_PUBLIC_IP}:~/docker-compose.yml"
                        }

                        dir('app-repo') {
                            bat "scp -o StrictHostKeyChecking=no -i \"${SSH_KEY}\" -r . ubuntu@${env.EC2_PUBLIC_IP}:~/app-repo"
                        }

                        bat "ssh -o StrictHostKeyChecking=no -i \"${SSH_KEY}\" ubuntu@${env.EC2_PUBLIC_IP} \"cd ~/app-repo && sudo docker build -t crud-app . && cd ~ && sudo docker-compose up -d\""

                        echo "Application deployment initiated. Check EC2 for status."
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
