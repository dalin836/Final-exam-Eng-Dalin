pipeline {
    agent any

    triggers {
        // Poll Git repository every 5 minutes
        pollSCM('H/5 * * * *')
    }

    environment {
        MVN_HOME = tool 'Maven'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh "${MVN_HOME}/bin/mvn clean compile"
            }
        }

        stage('Test') {
            steps {
                sh "${MVN_HOME}/bin/mvn test"
            }
        }

        stage('Package') {
            steps {
                sh "${MVN_HOME}/bin/mvn package -DskipTests"
            }
        }

        stage('Deploy with Ansible') {
            steps {
                sh 'ansible-playbook deploy.yml'
            }
        }
    }

    post {

        success {
            echo "Build and deployment successful."
        }

        failure {
            emailext(
                subject: "Jenkins Build Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
The Jenkins build has failed.

Project: ${env.JOB_NAME}
Build Number: ${env.BUILD_NUMBER}
Build URL: ${env.BUILD_URL}

Please review the logs.
""",
                recipientProviders: [
                    [$class: 'DevelopersRecipientProvider']
                ],
                to: 'srengty@gmail.com'
            )
        }
    }
}