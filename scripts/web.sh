#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-0}")" && pwd)"
REPOSITORY_ROOT_DIR="$(dirname "${SCRIPT_DIR}")"

source "${REPOSITORY_ROOT_DIR}/env/$1"

TEMPLATE_FILE=${ECS_WEB_TEMPLATE}
STACK_NAME=${ECS_WEB_STACK_NAME}

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
      DomainName=${DOMAIN_NAME} \
      HostedZoneId=${HOSTED_ZONE_ID} \
      DockerImageTag=${WEB_DOCKER_IMAGE_TAG}
