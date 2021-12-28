#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-0}")" && pwd)"
REPOSITORY_ROOT_DIR="$(dirname "${SCRIPT_DIR}")"

source "${REPOSITORY_ROOT_DIR}/env/dev"

TEMPLATE_FILE=${S3_TEMPLATE}
STACK_NAME=${S3_STACK_NAME}

EXIST_CHECK=$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} --query 'Stacks[].StackName | [0]' --output text)
if [ "${EXIST_CHECK}" = "${STACK_NAME}" ]; then
  METHOD=update-stack
else
  METHOD=create-stack
fi

# create or update stack
echo "${METHOD} ${STACK_NAME}"
aws cloudformation ${METHOD} \
    --stack-name "${STACK_NAME}" \
    --template-body "file://${REPOSITORY_ROOT_DIR}/templates/${TEMPLATE_FILE}" \
    --region "${REGION}" \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --parameters \
      ParameterKey=Project,ParameterValue=${PROJ} \
      ParameterKey=Env,ParameterValue=${ENV} \
      ParameterKey=LambdaFunctionsBucketName,ParameterValue=${LAMBDA_FUNCTIONS_BUCKET_NAME} \
      ParameterKey=DataBucketName,ParameterValue=${DATA_BUCKET_NAME} \
    --tags \
      Key=Project,Value=${PROJ} \
      Key=Environment,Value=${ENV}

# wait create or update stack complete
SUCCESS=('CREATE_COMPLETE' 'UPDATE_COMPLETE')
FAILED=('ROLLBACK_COMPLETE' 'UPDATE_ROLLBACK_COMPLETE' 'ROLLBACK_FAILED' 'UPDATE_ROLLBACK_FAILED' 'ROLLBACK_IN_PROGRESS' 'UPDATE_ROLLBACK_IN_PROGRESS')
for i in {1..90}
do
  STATE=$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} --region ${REGION} --query 'Stacks[].StackStatus' --output text)
  if printf '%s\n' "${SUCCESS[@]}" | grep -qx "${STATE}" > /dev/null >&2; then
    break
  fi
  if printf '%s\n' "${FAILED[@]}" | grep -qx "${STATE}" > /dev/null >&2; then
    echo "Rollback stack ${STACK_NAME}"
    exit 1
  fi
  echo "wait 20 sec..."
  sleep 20
done

echo "Complete ${METHOD} ${STACK_NAME}"
