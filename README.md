### Building Images On EKS Fargate

Create 3x ECR Repositories

```
JENKINS_AGENT_REPOSITORY=$(aws ecr create-repository --repository-name jenkins | jq -r '.repository.repositoryUri')
KANIKO_REPOSITORY=$(aws ecr create-repository --repository-name kaniko | jq -r '.repository.repositoryUri')
MYSFITS_REPOSITORY=$(aws ecr create-repository --repository-name mysfits| jq -r '.repository.repositoryUri')
```

Prepare Jenkins Agent Image

```
docker pull jenkins/inbound-agent:4.3-4-alpine
docker tag docker.io/jenkins/inbound-agent:4.3-4-alpine $JENKINS_AGENT_REPOSITORY
docker push $JENKINS_AGENT_REPOSITORY
```

Prepare Kaniko Image

```
$ /kaniko$ tree
.
├── Dockerfile
└── config.json

$ cat config.json 
{ "credsStore": "ecr-login" }

$ cat Dockerfile 
FROM gcr.io/kaniko-project/executor:debug

COPY ./config.json /kaniko/.docker/config.json

$ docker build -t $KANIKO_REPOSITORY .
$ docker push $KANIKO_REPOSITORY
```

Create IAM Role to be used by a Kubernetes Service Account. 

```
eksctl create iamserviceaccount \
    --name jenkins-sa-agent \
    --namespace default \
    --cluster fargate-jenkins-cluster \
    --attach-policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser \
    --approve \
    --override-existing-serviceaccounts
```

Create a Jenkins Pipeline Job in the UI. And use the attached [Jenkinsfile](./jenkinsfile)