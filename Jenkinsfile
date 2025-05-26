pipeline {
    agent any
    environment {
        DOCKER_IMAGE = 'restapiapp'
    }
    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/SkrytyZubr/crud-app-spring-restapi-db.git', branch: 'main'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build(env.DOCKER_IMAGE)
                }
            }
        }
        stage('Run Docker Container') {
           steps {
                bat 'docker-compose up -d --build'
            }
        }
    }
}
