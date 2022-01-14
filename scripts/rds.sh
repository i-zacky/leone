#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-0}")" && pwd)"
REPOSITORY_ROOT_DIR="$(dirname "${SCRIPT_DIR}")"

source "${REPOSITORY_ROOT_DIR}/env/$1"

TEMPLATE_FILE=${RDS_TEMPLATE}
STACK_NAME=${RDS_STACK_NAME}

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
      SecurityGroupStackName=${SG_STACK_NAME} \
      DatabaseName=${DATABASE_NAME} \
      DatabaseUser=${DATABASE_UER} \
      DatabasePassword=${DATABASE_PASSWORD}
