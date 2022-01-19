#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-0}")" && pwd)"
REPOSITORY_ROOT_DIR="$(dirname "${SCRIPT_DIR}")"

if [ -z "$1" ]; then
  echo "[ERROR] required action command: deploy / delete"
  exit 1
fi
if [ -z "$2" ]; then
  echo "[ERROR] required env parameter"
  exit 1
fi

source "${REPOSITORY_ROOT_DIR}/env/$2"

TEMPLATE_FILE=${ECS_API_TEMPLATE}
STACK_NAME=${ECS_API_STACK_NAME}

if [ "delete" = "$1" ]; then
  sam delete \
    --region "${REGION}" \
    --no-prompts \
    --stack-name "${STACK_NAME}"
elif [ "deploy" = "$1" ]; then
  HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name ${DOMAIN_NAME} --query "HostedZones[0].Id" --output text | sed "s/^\/hostedzone\///")
  sam deploy \
    --region "${REGION}" \
    --template "${REPOSITORY_ROOT_DIR}/templates/${TEMPLATE_FILE}" \
    --stack-name "${STACK_NAME}" \
    --s3-bucket "${CF_TEMPLATE_BUCKET}" \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --no-fail-on-empty-changeset \
    --tags \
        Env="${ENV}" \
        Project="${PROJ}" \
    --parameter-overrides \
        Project=${PROJ} \
        Env=${ENV} \
        VPCStackName=${VPC_STACK_NAME} \
        SGStackName=${SG_STACK_NAME} \
        ECRStackName=${ECR_STACK_NAME} \
        ECSStackName=${ECS_STACK_NAME} \
        ACMStackName=${ACM_STACK_NAME} \
        S3StackName=${S3_STACK_NAME} \
        RDSStackName=${RDS_STACK_NAME} \
        CognitoStackName=${COGNITO_STACK_NAME} \
        DomainName=${API_DOMAIN_NAME} \
        HostedZoneId=${HOSTED_ZONE_ID} \
        DockerImageTag=${API_DOCKER_IMAGE_TAG} \
        TaskCPU=${API_TASK_CPU} \
        TaskMemory=${API_TASK_MEMORY} \
        AllowOrigin=${ALLOW_ORIGIN} \
        ClockFixed=${CLOCK_FIXED}
else
  echo "[ERROR] unknown action command"
  exit 1
fi
