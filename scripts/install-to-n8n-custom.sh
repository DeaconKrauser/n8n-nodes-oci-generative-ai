#!/usr/bin/env bash
# Links the built package into the n8n self-hosted custom nodes directory.
# Run after: npm run build && npm link
#
# Usage:
#   ./scripts/install-to-n8n-custom.sh
#
# Optional env:
#   N8N_CUSTOM_DIR=~/.n8n/custom   (default)

set -euo pipefail
IFS=$'\n\t'

readonly PACKAGE_NAME="n8n-nodes-oci-generative-ai"
readonly N8N_CUSTOM_DIR="${N8N_CUSTOM_DIR:-${HOME}/.n8n/custom}"

main() {
	if ! command -v npm >/dev/null 2>&1; then
		echo "Error: npm not found in PATH." >&2
		exit 1
	fi

	mkdir -p "${N8N_CUSTOM_DIR}"
	cd "${N8N_CUSTOM_DIR}"

	if [[ ! -f package.json ]]; then
		npm init -y
	fi

	npm link "${PACKAGE_NAME}"

	echo "Linked: ${PACKAGE_NAME} -> ${N8N_CUSTOM_DIR}"
	echo "Restart n8n and search for \"Oracle OCI\" or \"OCI GenAI\" in the editor."
	echo "If using Docker: the container must share the same HOME or use N8N_CUSTOM_EXTENSIONS with a mounted path."
}

main "$@"
