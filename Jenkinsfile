pipeline {
    agent {
        label 'fargate-workers'
    }

    stages {
        stage('Clone') {
            steps {
                echo "Cloning Repo"
                sh "git clone https://github.com/ollypom/mysfits.git /data/myapp"
                echo "Repo Cloned"
                echo "Get the Kaniko Command Ready"
                sh '''
                cat <<EOF >>/data/executer.sh
                #!/busybox/sh
                /kaniko/executor \
                --context "dir:///data/myapp/api/" \
                --dockerfile "Dockerfile.v4" \
                --destination "111222333444.dkr.ecr.eu-west-1.amazonaws.com/mysfits:latest" \
                --force > /data/buildlogs 2>> /data/buildlogs
                '''
            }
        }
        stage('Build Container') {
            stages {
                stage('Trigger Build') {
                    steps {
                        sh "touch /data/ready"
                    }
                }
                stage('Watch Build') {
                    failFast true
                    parallel {
                        stage('Build Logs') {
                            steps {
                                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                    sh "touch /data/buildlogs"
                                    sh "tail -f /data/buildlogs"
                                }
                            }
                        }
                        stage('Build Lifecyle') {
                            steps {
                                sh '''
                                STATUS=RUNNING
                                while [ $STATUS == "RUNNING" ]
                                do
                                    STATUS=$(curl --silent ${ECS_CONTAINER_METADATA_URI_V4}/task | jq -r '.Containers | .[] | select(.Name == "kaniko") | .KnownStatus')
                                    echo "Still Building"
                                    sleep 2
                                done

                                pkill --signal 15 tail

                                EXIT_CODE=$(curl --silent ${ECS_CONTAINER_METADATA_URI_V4}/task | jq -r '.Containers | .[] | select(.Name == "kaniko") | .ExitCode')

                                if [ $EXIT_CODE = 1 ]
                                then
                                    exit 1
                                else
                                    exit 0
                                fi
                                '''
                            }
                        }
                    }
                }
            }
        }
    }
}