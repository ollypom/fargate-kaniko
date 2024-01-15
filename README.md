# Building container images on AWS Fargate with Kaniko

This repository contains an example ECS [task
definition](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html)
that you can use to run the [Google
Kaniko](https://github.com/GoogleContainerTools/kaniko) container image builder
inside of an Amazon ECS task on AWS Fargate. This repository is related to the
blog on the same topic [Building container images on Amazon ECS on AWS
Fargate](https://aws.amazon.com/blogs/containers/building-container-images-on-amazon-ecs-on-aws-fargate/)

### Why is this needed?

Traditional container image builders (`docker build`) can not run in the default
isolation boundary of a container without additional privileges or without
access to the underlying container runtime. In AWS Fargate, as you are not able
to run a container with additional privileges and you are not able to access the
underlying container runtime a rootless builder is required.

## Walkthrough

This repository contains a [task
definition](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html)
and a [run
task](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_run_task-v2.html)
instruction for Amazon ECS. This run task call could be triggered be a CI
pipeline easily enough.

**Prerequisites**

This repository assumes some core AWS infrastructure is in place.

- An existing VPC, Subnet and Security Group (No inbound access is required in
  the security group). The values in `kaniko-runtask.json` need to be replaced
  with your appropriate values.
- An existing Amazon ECS Cluster to place the task.
- An Amazon ECR Repository to push the sample application container image too.
- An IAM Role to be used as a [Amazon ECS task execution
  role](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html)

**Create the IAM Task Role**

The [task IAM
role](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html)
provides permissions to the application within our container. In this context
the application is kaniko and it will need the relevant IAM permissions to push
a container image to an Amazon ECR Repository.

1. Create the IAM Task Role

```bash
aws iam create-role \
    --role-name AmazonEcsKanikoTaskRole \
    --assume-role-policy-document file://iam-trust-policy.json
```

2. Attach a policy with the permissions to push container image to ECR to the
   Kaniko Task Role.

```bash
aws iam attach-role-policy \
    --role-name AmazonEcsKanikoTaskRole \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser
```

**Create a Cloudwatch Log Group**

Next we will create a Cloudwatch Log Group with a short retention policy for
our build logs to go to.

```bash
aws logs create-log-group \
    --log-group-name /aws/ecs/service/kaniko

aws logs put-retention-policy \
    --log-group-name /aws/ecs/service/kaniko \
    --retention-in-days 7
```

**Create ECS Task Definition**

The "commands" in the kaniko container definition set the build context and the
location of the Dockerfile. These will need to be updated depending on the
layout of your application repository.

```
aws ecs register-task-definition \
    --family kaniko-builder \
    --cli-input-json file://kaniko-taskdef.json
```

**Run the Task**

Finally we can run the ECS Task. This Run Task definition will also need to
updated with the relevant AWS VPC, Subnet, Security Group and ECS Cluster.

```
aws ecs run-task \
    --task-definition kaniko-builder \
    --cli-input-json file://kaniko-runtask.json
```

Now you can monitor the build in Cloudwatch Logs and watch the ECR repository
for your new container image :)

### Cleanup

1. Delete the Amazon ECS Task IAM Role

```bash
aws iam detach-role-policy \
    --role-name AmazonEcsKanikoTaskRole \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser

aws iam delete-role \
    --role-name AmazonEcsKanikoTaskRole
```

2. Remove the Cloudwatch Log Group

```bash
aws logs delete-log-group \
    --log-group-name /aws/ecs/service/kaniko
```

3. Deregister the Task Definition

```bash
TASK_DEFS=$(aws ecs list-task-definitions --family-prefix kaniko-builder | jq -r '.taskDefinitionArns.[]')
for TASK_DEF in $TASK_DEFS; do aws ecs deregister-task-definition --task-definition $TASK_DEF; done
```