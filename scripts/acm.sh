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

TEMPLATE_FILE=${ACM_TEMPLATE}
STACK_NAME=${ACM_STACK_NAME}

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
        HostedZoneId=${HOSTED_ZONE_ID} \
        DomainName=${DOMAIN_NAME}
else
  echo "[ERROR] unknown action command"
  exit 1
fi
