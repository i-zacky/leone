#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-0}")" && pwd)"
REPOSITORY_ROOT_DIR="$(dirname "${SCRIPT_DIR}")"

source "${REPOSITORY_ROOT_DIR}/env/$1"

TEMPLATE_FILE=${COGNITO_TEMPLATE}
STACK_NAME=${COGNITO_STACK_NAME}

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
      AdministratorEmail=${ADMINISTRATOR_EMAIL}

echo "Update administrator password. ${STACK_NAME}"
USER_POOL_ID=$(aws cloudformation describe-stacks --stack-name "${STACK_NAME}" --query "Stacks[].Outputs[?ExportName==\`${STACK_NAME}-user-pool-id\`].[OutputValue]" --output text)
aws cognito-idp admin-set-user-password \
  --user-pool-id "${USER_POOL_ID}" \
  --username "${ADMINISTRATOR_EMAIL}" \
  --password "${ADMINISTRATOR_PASSWORD}" \
  --permanent
