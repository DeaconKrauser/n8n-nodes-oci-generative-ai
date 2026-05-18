#!/usr/bin/env bash
# Copies the Docker Compose merge files to the remote server and runs docker compose up.
#
# Usage:
#   REMOTE=ubuntu@YOUR_VPS_IP ./scripts/push-compose-merge-and-up.sh
#
# Optional env:
#   REMOTE_N8N_DIR=/home/ubuntu/n8n
#   SKIP_UP=1   (copy files only, do not run compose up)
#   DEPLOY_SSH_IDENTITY_FILE=$HOME/.ssh/n8n_deploy

set -euo pipefail
IFS=$'\n\t'

readonly REMOTE="${REMOTE:?Set REMOTE=ubuntu@YOUR_VPS_IP before running this script}"
readonly REMOTE_N8N_DIR="${REMOTE_N8N_DIR:-/home/ubuntu/n8n}"
readonly REMOTE_DATA_DIR="${REMOTE_DATA_DIR:-/home/ubuntu/n8n/data}"

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly DEPLOY_DIR="${PACKAGE_ROOT}/deploy"

readonly SSH_OPTS_BASE=(-o StrictHostKeyChecking=accept-new)
SSH_OPTS=("${SSH_OPTS_BASE[@]}")
if [[ -n "${DEPLOY_SSH_IDENTITY_FILE:-}" ]]; then
	if [[ ! -r "${DEPLOY_SSH_IDENTITY_FILE}" ]]; then
		echo "Error: DEPLOY_SSH_IDENTITY_FILE not readable: ${DEPLOY_SSH_IDENTITY_FILE}" >&2
		exit 1
	fi
	SSH_OPTS+=(-i "${DEPLOY_SSH_IDENTITY_FILE}")
fi

SSH_CMD=(ssh "${SSH_OPTS[@]}" "${REMOTE}")
SCP_CMD=(scp "${SSH_OPTS[@]}")

if [[ ! -f "${DEPLOY_DIR}/docker-compose.oci-merge-main.EXAMPLE.yml" ]]; then
	echo "Error: ${DEPLOY_DIR}/docker-compose.oci-merge-main.EXAMPLE.yml not found" >&2
	exit 1
fi

echo "Remote: ${REMOTE}  n8n dir: ${REMOTE_N8N_DIR}"

"${SSH_CMD[@]}" "mkdir -p '${REMOTE_DATA_DIR}' '${REMOTE_N8N_DIR}/custom-extensions/n8n-nodes-oci-generative-ai' && (chown -R 1000:1000 '${REMOTE_DATA_DIR}' 2>/dev/null || sudo chown -R 1000:1000 '${REMOTE_DATA_DIR}' || true)"

"${SCP_CMD[@]}" \
	"${DEPLOY_DIR}/docker-compose.oci-merge-main.EXAMPLE.yml" \
	"${REMOTE}:${REMOTE_N8N_DIR}/docker-compose.oci-merge-main.yml"

"${SCP_CMD[@]}" \
	"${DEPLOY_DIR}/docker-compose.oci-merge-worker.EXAMPLE.yml" \
	"${REMOTE}:${REMOTE_N8N_DIR}/docker-compose.oci-merge-worker.yml"

echo "YAML files copied to ${REMOTE}:${REMOTE_N8N_DIR}/docker-compose.oci-merge-*.yml"

if [[ "${SKIP_UP:-0}" == "1" ]]; then
	echo "SKIP_UP=1 — skipping docker compose up."
	exit 0
fi

"${SSH_CMD[@]}" "cd '${REMOTE_N8N_DIR}' && docker compose \
	-f docker-compose-main.yml -f docker-compose.oci-merge-main.yml \
	-f docker-compose-worker.yml -f docker-compose.oci-merge-worker.yml \
	up -d"

echo "Compose up done. Reinstall community nodes via the n8n UI if node_modules was empty."
