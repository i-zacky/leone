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

TEMPLATE_FILE=${ROOT_TEMPLATE}
STACK_NAME=${ROOT_STACK_NAME}

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
        CIDR="${CIDR}" \
        HostedZoneId="${HOSTED_ZONE_ID}" \
        DomainName="${DOMAIN_NAME}" \
        AdministratorEmail="${ADMINISTRATOR_EMAIL}" \
        DatabaseName="${DATABASE_NAME}" \
        MasterUsername="${DATABASE_UER}" \
        BastionKeyPairName="${BASTION_KEY_PAIR_NAME}"

  echo "Update administrator password. ${STACK_NAME}"
  USER_POOL_ID=$(aws cloudformation describe-stacks --stack-name "${STACK_NAME}" --query "Stacks[].Outputs[?OutputKey==\`CognitoUserPoolId\`].[OutputValue]" --output text)
  ADMINISTRATOR_SECRET_ARN=$(aws cloudformation describe-stacks --stack-name "${STACK_NAME}" --query "Stacks[].Outputs[?OutputKey==\`AdministratorUserSecretArn\`].[OutputValue]" --output text)
  ADMINISTRATOR_PASSWORD=$(aws secretsmanager get-secret-value --secret-id "${ADMINISTRATOR_SECRET_ARN}" --query "SecretString" | jq -r 'fromjson | .password')
  aws cognito-idp admin-set-user-password \
    --user-pool-id "${USER_POOL_ID}" \
    --username "${ADMINISTRATOR_EMAIL}" \
    --password "${ADMINISTRATOR_PASSWORD}" \
    --permanent

else
  echo "[ERROR] unknown action command"
  exit 1
fi
