#!/usr/bin/env bash
# Autor: desenvolvimentos
# Data: 2026-05-13
# Propósito: após `npm run build` e `npm link` na raiz deste pacote, liga o pacote ao diretório
#            de community nodes do n8n self-hosted (por defeito ~/.n8n/custom).

set -euo pipefail
IFS=$'\n\t'

readonly PACKAGE_NAME="n8n-nodes-oci-generative-ai"
readonly N8N_CUSTOM_DIR="${N8N_CUSTOM_DIR:-${HOME}/.n8n/custom}"

main() {
	if ! command -v npm >/dev/null 2>&1; then
		echo "Erro: npm não está no PATH." >&2
		exit 1
	fi

	mkdir -p "${N8N_CUSTOM_DIR}"
	cd "${N8N_CUSTOM_DIR}"

	if [[ ! -f package.json ]]; then
		npm init -y
	fi

	npm link "${PACKAGE_NAME}"

	echo "Ligado: ${PACKAGE_NAME} -> ${N8N_CUSTOM_DIR}"
	echo "Reinicie o n8n e procure no editor por \"Oracle OCI\" ou \"OCI GenAI\"."
	echo "Se usar Docker: o contentor precisa de ver o mesmo HOME ou definir N8N_CUSTOM_EXTENSIONS e montar esse caminho."
}

main "$@"
