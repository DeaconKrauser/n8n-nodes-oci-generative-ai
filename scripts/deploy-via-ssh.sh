#!/usr/bin/env bash
# Autor: desenvolvimentos
# Data: 2026-05-14
# Propósito: copiar este pacote (com dist/ pré-compilado localmente) para o servidor por SSH.
#            Por defeito envia o dist/ local — sem build remoto. Mais simples e sem problemas de
#            dependências nativas do @n8n/node-cli no servidor.
#
# Uso (o primeiro argumento é o destino SSH do rsync, igual a `ssh` — hostname OU IP):
#   ./scripts/deploy-via-ssh.sh ubuntu@192.168.1.50:/home/ubuntu/n8n/custom-extensions/n8n-nodes-oci-generative-ai
#   ./scripts/deploy-via-ssh.sh ubuntu@vps.exemplo.com:/home/ubuntu/n8n/custom-extensions/n8n-nodes-oci-generative-ai
#
# ANTES de correr: certifica-te de que fizeste build local:
#   cd /path/to/n8n-nodes-oci-generative-ai && npm ci && npm run build
#
# Sugestão: manter o pacote dentro da pasta do projeto n8n no servidor (ex.: ~/n8n/custom-extensions/...)
# para volumes no docker-compose ficarem relativos a ~/n8n.
#
# Opções:
#   REMOTE_BUILD=1      — em vez de enviar dist/, compila no servidor (host npm). Requer Node/npm no servidor.
#   USE_DOCKER_BUILD=1  — compila no servidor dentro de Docker (instala python3/make/g++ para deps nativas).
#   DOCKER_BUILD_IMAGE=  — imagem Docker (por defeito node:22-bookworm-slim).
#   DEPLOY_SSH_IDENTITY_FILE=/caminho/chave  — passa `-i` ao ssh/rsync.
#   SSHPASS=<senha>     — autentica por password via `sshpass`.
#   RSYNC_DELETE=1      — usa --delete no rsync (espelho exacto).

set -euo pipefail
IFS=$'\n\t'

readonly DEPLOY_TARGET="${1:?Uso: $0 utilizador@IP_OU_HOST:/caminho/absoluto/para/n8n-nodes-oci-generative-ai (ex.: ubuntu@203.0.113.10:/home/ubuntu/n8n/custom-extensions/n8n-nodes-oci-generative-ai)}"

readonly REMOTE="${DEPLOY_TARGET%%:*}"
readonly REMOTE_DIR="${DEPLOY_TARGET#*:}"

if [[ "${DEPLOY_TARGET}" != *:* ]]; then
	echo "Erro: use utilizador@host:/caminho ou utilizador@IP:/caminho (caminho absoluto no servidor)." >&2
	exit 1
fi

if [[ "${REMOTE_DIR}" != /* ]]; then
	echo "Erro: o caminho remoto tem de ser absoluto (começar por /)." >&2
	exit 1
fi

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

readonly SSH_OPTS_BASE=(-o StrictHostKeyChecking=accept-new)
SSH_OPTS=("${SSH_OPTS_BASE[@]}")
if [[ -n "${DEPLOY_SSH_IDENTITY_FILE:-}" ]]; then
	if [[ ! -r "${DEPLOY_SSH_IDENTITY_FILE}" ]]; then
		echo "Erro: DEPLOY_SSH_IDENTITY_FILE não legível: ${DEPLOY_SSH_IDENTITY_FILE}" >&2
		exit 1
	fi
	SSH_OPTS+=(-i "${DEPLOY_SSH_IDENTITY_FILE}")
fi

_ssh_for_rsync=$(printf "%q " "${SSH_OPTS[@]}")
_ssh_for_rsync=${_ssh_for_rsync%% }

if [[ -n "${SSHPASS:-}" ]]; then
	if ! command -v sshpass >/dev/null 2>&1; then
		echo "Erro: SSHPASS definido mas \`sshpass\` não está instalado. Instale: sudo apt-get install -y sshpass" >&2
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
	# Envia tudo incluindo dist/ pré-compilado — sem build remoto.
	if [[ ! -f "${PACKAGE_ROOT}/dist/nodes/LmChatOciGenAi/LmChatOciGenAi.node.js" ]]; then
		echo "Erro: dist/ não encontrado ou incompleto. Corre localmente: npm ci && npm run build" >&2
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
		echo "Modo: build remoto Docker..."
		sync_files_without_dist
		remote_build_docker_node
	elif [[ "${REMOTE_BUILD:-0}" == "1" ]]; then
		echo "Modo: build remoto host npm..."
		sync_files_without_dist
		remote_build_host_npm
	else
		echo "Modo: envio de dist/ pré-compilado local (padrão)..."
		sync_files_with_dist
	fi
	echo "Feito. Caminho no servidor: ${REMOTE_DIR}"
	echo "Monte esse caminho no contentor e defina N8N_CUSTOM_EXTENSIONS (ver deploy/DOCKER-COMPOSE-SNIPPET.txt)."
	echo "Para enviar merge compose e subir stack: ./scripts/push-compose-merge-and-up.sh"
}

main "$@"
