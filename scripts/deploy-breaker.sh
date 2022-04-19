#!/bin/bash

if [ -z "$1" ]; then
  echo "[ERROR] required stack name"
  exit 1
fi

if [ -z "$2" ]; then
  echo "[ERROR] required timeout seconds"
  exit 1
fi

STACK_NAME="$1"
TIMEOUT="$2"
MAX_RETRY=$((TIMEOUT / 10))

COMPLETE_STATUS=('CREATE_COMPLETE' 'UPDATE_COMPLETE')
IN_PROGRESS_STATUS=('CREATE_IN_PROGRESS' 'UPDATE_IN_PROGRESS')
ROLLBACK_STATUS=('ROLLBACK_IN_PROGRESS' 'ROLLBACK_FAILED' 'ROLLBACK_COMPLETE' 'UPDATE_FAILED' 'UPDATE_ROLLBACK_COMPLETE' 'UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS' 'UPDATE_ROLLBACK_FAILED' 'UPDATE_ROLLBACK_IN_PROGRESS')

for i in $(seq 1 12)
do
  STATE=$(aws cloudformation describe-stacks --stack-name "${STACK_NAME}" --query "Stacks[].StackStatus" --output text)
  if [[ "${IN_PROGRESS_STATUS[*]}" =~ ${STATE} ]]; then
    break
  fi
  sleep 5
done


for i in $(seq 1 ${MAX_RETRY})
do
  STATE=$(aws cloudformation describe-stacks --stack-name "${STACK_NAME}" --query "Stacks[].StackStatus" --output text)
  echo "stack name: ${STACK_NAME} / status: ${STATE}"

  if [[ "${COMPLETE_STATUS[*]}" =~ ${STATE} ]]; then
    echo "${STACK_NAME} in complete status."
    exit 0
  fi

  if [[ "${ROLLBACK_STATUS[*]}" =~ ${STATE} ]]; then
    echo "${STACK_NAME} in rollback status."
    exit 1
  fi

  if [ "${i}" -eq ${MAX_RETRY} ]; then
    echo "exceeded timeout seconds. cancel update stack..."
    aws cloudformation cancel-update-stack --stack-name "${STACK_NAME}"
    exit 1
  fi

  sleep 10
done
