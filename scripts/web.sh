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

TEMPLATE_FILE=${WEB_TEMPLATE}
STACK_NAME=${WEB_STACK_NAME}

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
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --no-fail-on-empty-changeset \
    --tags \
        Env="${ENV}" \
        Project="${PROJ}" \
    --parameter-overrides \
        Project="${PROJ}" \
        Env="${ENV}" \
        DomainName="${DOMAIN_NAME}" \
        HostedZoneId="${HOSTED_ZONE_ID}" \
        DockerImageTag="${WEB_DOCKER_IMAGE_TAG}" \
        TaskCPU="${WEB_TASK_CPU}" \
        TaskMemory="${WEB_TASK_MEMORY}" \
        TaskMinCapacity="${WEB_TASK_MIN_CAPACITY}" \
        TaskMaxCapacity="${WEB_TASK_MAX_CAPACITY}"
else
  echo "[ERROR] unknown action command"
  exit 1
fi
