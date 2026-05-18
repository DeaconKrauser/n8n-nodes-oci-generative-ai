#!/usr/bin/env bash
# Copies this package (with pre-compiled dist/) to the server via SSH.
# By default sends the local dist/ — no remote build needed.
#
# Usage:
#   ./scripts/deploy-via-ssh.sh ubuntu@YOUR_VPS_IP:/home/ubuntu/n8n/custom-extensions/n8n-nodes-oci-generative-ai
#
# Build locally first:
#   npm ci && npm run build
#
# Optional env:
#   REMOTE_BUILD=1          — build on the server using the host npm instead of sending dist/
#   USE_DOCKER_BUILD=1      — build on the server inside Docker (installs python3/make/g++ for native deps)
#   DOCKER_BUILD_IMAGE=     — Docker image to use (default: node:22-bookworm-slim)
#   DEPLOY_SSH_IDENTITY_FILE=/path/to/key  — passes -i to ssh/rsync
#   SSHPASS=<password>      — authenticate via password using sshpass
#   RSYNC_DELETE=1          — use --delete in rsync (exact mirror)

set -euo pipefail
IFS=$'\n\t'

readonly DEPLOY_TARGET="${1:?Usage: $0 user@HOST_OR_IP:/absolute/path/to/n8n-nodes-oci-generative-ai}"

readonly REMOTE="${DEPLOY_TARGET%%:*}"
readonly REMOTE_DIR="${DEPLOY_TARGET#*:}"

if [[ "${DEPLOY_TARGET}" != *:* ]]; then
	echo "Error: use user@host:/path or user@IP:/path (absolute path on the server)." >&2
	exit 1
fi

if [[ "${REMOTE_DIR}" != /* ]]; then
	echo "Error: remote path must be absolute (start with /)." >&2
	exit 1
fi

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

readonly SSH_OPTS_BASE=(-o StrictHostKeyChecking=accept-new)
SSH_OPTS=("${SSH_OPTS_BASE[@]}")
if [[ -n "${DEPLOY_SSH_IDENTITY_FILE:-}" ]]; then
	if [[ ! -r "${DEPLOY_SSH_IDENTITY_FILE}" ]]; then
		echo "Error: DEPLOY_SSH_IDENTITY_FILE not readable: ${DEPLOY_SSH_IDENTITY_FILE}" >&2
		exit 1
	fi
	SSH_OPTS+=(-i "${DEPLOY_SSH_IDENTITY_FILE}")
fi

_ssh_for_rsync=$(printf "%q " "${SSH_OPTS[@]}")
_ssh_for_rsync=${_ssh_for_rsync%% }

if [[ -n "${SSHPASS:-}" ]]; then
	if ! command -v sshpass >/dev/null 2>&1; then
		echo "Error: SSHPASS is set but sshpass is not installed. Install with: sudo apt-get install -y sshpass" >&2
		exit 1
	fi
	export SSHPASS
	SSH_CMD=(sshpass -e ssh "${SSH_OPTS[@]}")
	RSYNC_RSH_VAL="sshpass -e ssh ${_ssh_for_rsync}"
else
	SSH_CMD=(ssh "${SSH_OPTS[@]}")
	RSYNC_RSH_VAL="ssh ${_ssh_for_rsync}"
fi

sync_files_with_dist() {
	if [[ ! -f "${PACKAGE_ROOT}/dist/nodes/LmChatOciGenAi/LmChatOciGenAi.node.js" ]]; then
		echo "Error: dist/ not found or incomplete. Run locally: npm ci && npm run build" >&2
		exit 1
	fi
	"${SSH_CMD[@]}" "${REMOTE}" "mkdir -p '${REMOTE_DIR}'"
	local -a rsync_opts=(-avz)
	if [[ "${RSYNC_DELETE:-0}" == "1" ]]; then
		rsync_opts+=(--delete)
	fi
	RSYNC_RSH="${RSYNC_RSH_VAL}" rsync "${rsync_opts[@]}" \
		--exclude node_modules \
		--exclude .git \
		"${PACKAGE_ROOT}/" "${REMOTE}:${REMOTE_DIR}/"
}

sync_files_without_dist() {
	"${SSH_CMD[@]}" "${REMOTE}" "mkdir -p '${REMOTE_DIR}'"
	local -a rsync_opts=(-avz)
	if [[ "${RSYNC_DELETE:-0}" == "1" ]]; then
		rsync_opts+=(--delete)
	fi
	RSYNC_RSH="${RSYNC_RSH_VAL}" rsync "${rsync_opts[@]}" \
		--exclude node_modules \
		--exclude .git \
		--exclude dist \
		"${PACKAGE_ROOT}/" "${REMOTE}:${REMOTE_DIR}/"
}

remote_build_host_npm() {
	"${SSH_CMD[@]}" "${REMOTE}" "mkdir -p '${REMOTE_DIR}' && cd '${REMOTE_DIR}' && npm ci && npm run build"
}

remote_build_docker_node() {
	local img="${DOCKER_BUILD_IMAGE:-node:22-bookworm-slim}"
	"${SSH_CMD[@]}" "${REMOTE}" "mkdir -p '${REMOTE_DIR}'"
	"${SSH_CMD[@]}" "${REMOTE}" "docker run --rm \
		-v '${REMOTE_DIR}:/work' \
		-w /work \
		${img} \
		bash -lc 'set -euo pipefail; apt-get update -qq; apt-get install -y -qq python3 make g++ pkg-config; npm ci; npm run build'"
}

main() {
	if [[ "${USE_DOCKER_BUILD:-0}" == "1" ]]; then
		echo "Mode: remote Docker build..."
		sync_files_without_dist
		remote_build_docker_node
	elif [[ "${REMOTE_BUILD:-0}" == "1" ]]; then
		echo "Mode: remote host npm build..."
		sync_files_without_dist
		remote_build_host_npm
	else
		echo "Mode: sending pre-compiled dist/ (default)..."
		sync_files_with_dist
	fi
	echo "Done. Path on server: ${REMOTE_DIR}"
	echo "Mount that path in the container and set N8N_CUSTOM_EXTENSIONS (see deploy/DEPLOY.md)."
	echo "To push compose merge files and start the stack: ./scripts/push-compose-merge-and-up.sh"
}

main "$@"
