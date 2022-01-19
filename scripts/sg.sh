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

TEMPLATE_FILE=${SG_TEMPLATE}
STACK_NAME=${SG_STACK_NAME}

if [ "delete" = "$1" ]; then
  sam delete \
    --region "${REGION}" \
    --no-prompts \
    --stack-name "${STACK_NAME}"
elif [ "deploy" = "$1" ]; then
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
        PublicSubnetCIDRA=${PUBLIC_SUBNET_CIDR_A} \
        PublicSubnetCIDRC=${PUBLIC_SUBNET_CIDR_C} \
        PublicSubnetCIDRD=${PUBLIC_SUBNET_CIDR_D} \
        PrivateSubnetCIDRA=${PRIVATE_SUBNET_CIDR_A} \
        PrivateSubnetCIDRC=${PRIVATE_SUBNET_CIDR_C} \
        PrivateSubnetCIDRD=${PRIVATE_SUBNET_CIDR_D}
else
  echo "[ERROR] unknown action command"
  exit 1
fi
