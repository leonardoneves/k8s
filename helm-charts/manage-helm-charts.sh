#!/bin/bash
set -euo pipefail

# Function to display usage information
usage() {
  echo "Usage: $0 --action {install|sync|upgrade|apply|uninstall|destroy|reinstall} --profile <profile> [--environment <environment>] [--selector <selector>] [--debug] [--skip-sleep]"
  exit 1
}

# Initialize variables
ACTION=""
CLUSTER=""
ENVIRONMENT="prod"
SELECTOR=""
OPTIONS=""
SKIP_SLEEP="false"  # Default to not skipping sleep

# Parse command-line arguments using getopts
while getopts ":a:c:e:s:d-:" opt; do
  case ${opt} in
    -)
      case "${OPTARG}" in
        action)
          ACTION="${!OPTIND}"; OPTIND=$(( ${OPTIND} + 1 ))
          ;;
        profile)
          CLUSTER="${!OPTIND}"; OPTIND=$(( ${OPTIND} + 1 ))
          ;;
        environment)
          ENVIRONMENT="${!OPTIND}"; OPTIND=$(( ${OPTIND} + 1 ))
          ;;
        selector)
          SELECTOR="--selector ${!OPTIND}"; OPTIND=$(( ${OPTIND} + 1 ))
          ;;
        debug)
          OPTIONS="${OPTIONS} --debug"
          ;;
        skip-sleep)
          SKIP_SLEEP="true"
          ;;
        *)
          echo "Unknown option: --${OPTARG}"
          usage
          ;;
      esac
      ;;
    a)
      ACTION="${OPTARG}"
      ;;
    c)
      CLUSTER="${OPTARG}"
      ;;
    e)
      ENVIRONMENT="${OPTARG}"
      ;;
    s)
      SELECTOR="--selector ${OPTARG}"
      ;;
    d)
      OPTIONS="${OPTIONS} --debug"
      ;;
    \?)
      echo "Invalid option: -${OPTARG}" >&2
      usage
      ;;
    :)
      echo "Option -${OPTARG} requires an argument." >&2
      usage
      ;;
  esac
done

# Check if required arguments are provided
if [ -z "${ACTION}" ] || [ -z "${CLUSTER}" ]; then
  usage
fi

# Validate action argument
case ${ACTION} in
  install|sync|upgrade|apply|uninstall|destroy|reinstall)
    ;;
  *)
    usage
    ;;
esac

# Set environment variables
export CLUSTER
export ENVIRONMENT
export SKIP_SLEEP

# Perform the specified action
case ${ACTION} in
  install|sync|upgrade|apply)
    echo "Performing ${ACTION} on Helm charts for profile: ${CLUSTER}"
    helmfile -f helmfile.d/${CLUSTER} sync ${SELECTOR} ${OPTIONS}
    ;;
  uninstall|destroy)
    echo "Performing ${ACTION} on Helm charts for profile: ${CLUSTER}"
    helmfile -f helmfile.d/${CLUSTER} destroy ${SELECTOR} ${OPTIONS}
    ;;
  reinstall)
    echo "Performing ${ACTION} on Helm charts for profile: ${CLUSTER}"
    helmfile -f helmfile.d/${CLUSTER} destroy ${SELECTOR} ${OPTIONS}
    echo "Destroy completed, now installing again"
    helmfile -f helmfile.d/${CLUSTER} sync ${SELECTOR} ${OPTIONS}
    ;;
esac

echo "Action ${ACTION} complete on profile: ${CLUSTER}."
