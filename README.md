# Fargate Kaniko

A whole lot of WIP. But a Jenkins Agent Container and Kaniko Container deployed
in the same task. 

```
aws ecs register-task-definition \
    --family kaniko-jenkins \
    --cli-input-json file://kaniko-taskdef.json
```