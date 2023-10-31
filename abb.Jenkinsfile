pipeline {
    // This pipeline requires the following plugins:
    // * Git: https://plugins.jenkins.io/git/
    // * Workflow Aggregator: https://plugins.jenkins.io/workflow-aggregator/
     agent any
     environment {
     AWS_ACCOUNT_ID="YOUR_ACCOUNT_ID_HERE"
     AWS_DEFAULT_REGION="CREATED_AWS_ECR_CONTAINER_REPO_REGION"
     IMAGE_REPO_NAME="<ECR_REPO_NAME>"
     IMAGE_TAG="latest"
     REPOSITORY_URI = <ECR URI FROM TERRAFORM> //uri of repo created with terraform
     GIT_REPOSITORY = <YOUR GIT REPO GIT REPOSITORY URL>
     AWS_SERVICE_ROLE = <TERRAFORM SERVICE ROLE>
     AWS_SUBNET = <SUBNET FROM TERRAFORM>
     AWS_SG = <SERVICE SG FROM TERRAFORM>
     APP_TG= <TG FROM TERRRAFORM>
     }

     stages {
         stage('Logging into AWS ECR') {
             steps {
                 script {
                     sh "aws ecr get-login-password - region ${AWS_DEFAULT_REGION} | \
                     docker login - username AWS - password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"
                 }
         }

         stage('Cloning Git') {
             steps {
             checkout([$class: 'GitSCM',
                        branches: [[name: '*/master']],
                        doGenerateSubmoduleConfigurations: false,
                        extensions: [],
                        submoduleCfg: [],
                        userRemoteConfigs: [[credentialsId: '', url: GIT_REPOSITORY]]])
             }
         }

         // Building Docker images
         stage('Building image') {
             steps{
                 script {
                    app = docker.build "${IMAGE_REPO_NAME}:${IMAGE_TAG}"
                 }
             }
         }
         // Run UnitTest inside docker
         stage('Test'){
            steps {
                script {
                    sh "docker run --tty -t ${IMAGE_REPO_NAME}:${IMAGE_TAG} python -m unittest -v"
                }
            }
        }

         // Uploading Docker images into AWS ECR
         stage('Pushing to ECR') {
             steps{
                 script {
                     sh "docker tag ${IMAGE_REPO_NAME}:${IMAGE_TAG} ${REPOSITORY_URI}:${IMAGE_TAG}"
                     sh "docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}:${IMAGE_TAG}"
                 }
             }
         }

         // Register TaskDefinition with new image
         stage('Register TaskDefinition') {
             steps{
                 script {
                     def taskDefinition = readJSON text: '{
                                                    "family": "abb_app-fargate",
                                                    "networkMode": "awsvpc",
                                                    "targetType":"ip"
                                                    "taskRoleArn": "${AWS_SERVICE_ROLE}",
                                                    "containerDefinitions": [
                                                        {
                                                            "name": "visitors-app",
                                                            "image": "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}:${IMAGE_TAG}",
                                                            "portMappings": [
                                                                {
                                                                    "containerPort": 4000,
                                                                    "hostPort": 4000,
                                                                    "protocol": "tcp"
                                                                }
                                                            ],
                                                            "logConfiguration": {
                                                                "logDriver": "awslogs",
                                                                "options": {
                                                                  "awslogs-create-group": "True",
                                                                  "awslogs-group": "/ecs/abb_app-fargate",
                                                                  "awslogs-region": "{{region}}",
                                                                  "awslogs-stream-prefix": "ecs"
                                                                }
                                                            }
                                                        }
                                                    ],
                                                    "requiresCompatibilities": [
                                                        "FARGATE"
                                                    ],
                                                    "cpu": "256",
                                                    "memory": "512"
                                            }'
                     def output = sh(script: "aws ecs register-task-definition --cli-input-json ${taskDefinition}", returnStdout: true)
                     def outObject = readJSON(output)
                     def taskDefinitionRevision = outObject.taskDefinition.revision
                 }
             }
         }

         // Deploy to ECS
         stage('Create Fargate Service') {
             steps{
                 script {
                     sh "aws ecs create-service \
                     --cluster abb-cluster \
                     --service-name visitors-service \
                     --load-balancers [{targetGroupArn=${APP_TG},containerName=fargate-app,containerPort=4000}] \
                     --task-definition ${IMAGE_REPO_NAME}:${taskDefinitionRevision} \
                     --desired-count 1 \
                     --launch-type 'FARGATE' \
                     --network-configuration 'awsvpcConfiguration={subnets=[${AWS_SUBNET}],securityGroups=[${AWS_SG}]}' \
                     --enable-execute-command"
                 }
             }
         }
     }
}
