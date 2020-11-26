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
                --dockerfile "Dockerfile.v1" \
                --destination "223615444511.dkr.ecr.eu-west-1.amazonaws.com/mysfits:v1latest" \
                --force
                '''
            }
        }
        stage('Build') {
            steps {
                echo "Triggering Build"
                sh "touch /data/ready"
                echo "Watching for Build"
                sh '''
                STATUS=RUNNING
                while [ $STATUS == "RUNNING" ]
                do
                    STATUS=$(curl --silent ${ECS_CONTAINER_METADATA_URI_V4}/task | jq -r '.Containers | .[] | select(.Name == "kaniko") | .KnownStatus')
                    echo "Still Building"
                    sleep 2
                done
                '''
                echo "Build Complete"
            }
        }
    }
}