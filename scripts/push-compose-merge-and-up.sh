#!/usr/bin/env bash
# Propósito: enviar os merge YAML do repo para o VPS, criar /home/ubuntu/n8n/data
#            e subir n8n com docker compose (main + worker + merges OCI).
#
# Uso (no PC de dev, a partir da pasta do pacote):
#   DEPLOY_SSH_IDENTITY_FILE="$HOME/.ssh/n8n_deploy" ./scripts/push-compose-merge-and-up.sh
#
# Variáveis opcionais:
#   REMOTE=ubuntu@YOUR_VPS_IP
#   REMOTE_N8N_DIR=/home/ubuntu/n8n   (directório no servidor onde estão os compose)
#   SKIP_UP=1                         (só copia YAML e cria pasta, não corre compose up)

set -euo pipefail
IFS=$'\n\t'

readonly REMOTE="${REMOTE:?Defina REMOTE=ubuntu@SEU_IP_VPS antes de correr este script}"
readonly REMOTE_N8N_DIR="${REMOTE_N8N_DIR:-/home/ubuntu/n8n}"
readonly REMOTE_DATA_DIR="${REMOTE_DATA_DIR:-/home/ubuntu/n8n/data}"

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly DEPLOY_DIR="${PACKAGE_ROOT}/deploy"

readonly SSH_OPTS_BASE=(-o StrictHostKeyChecking=accept-new)
SSH_OPTS=("${SSH_OPTS_BASE[@]}")
if [[ -n "${DEPLOY_SSH_IDENTITY_FILE:-}" ]]; then
	if [[ ! -r "${DEPLOY_SSH_IDENTITY_FILE}" ]]; then
		echo "Erro: DEPLOY_SSH_IDENTITY_FILE não legível: ${DEPLOY_SSH_IDENTITY_FILE}" >&2
		exit 1
	fi
	SSH_OPTS+=(-i "${DEPLOY_SSH_IDENTITY_FILE}")
fi

SSH_CMD=(ssh "${SSH_OPTS[@]}" "${REMOTE}")
SCP_CMD=(scp "${SSH_OPTS[@]}")

if [[ ! -f "${DEPLOY_DIR}/docker-compose.oci-merge-main.EXAMPLE.yml" ]]; then
	echo "Erro: não encontro ${DEPLOY_DIR}/docker-compose.oci-merge-main.EXAMPLE.yml" >&2
	exit 1
fi

echo "Remoto: ${REMOTE}  projecto n8n: ${REMOTE_N8N_DIR}"

"${SSH_CMD[@]}" "mkdir -p '${REMOTE_DATA_DIR}' '${REMOTE_N8N_DIR}/custom-extensions/n8n-nodes-oci-generative-ai' && (chown -R 1000:1000 '${REMOTE_DATA_DIR}' 2>/dev/null || sudo chown -R 1000:1000 '${REMOTE_DATA_DIR}' || true)"

"${SCP_CMD[@]}" \
	"${DEPLOY_DIR}/docker-compose.oci-merge-main.EXAMPLE.yml" \
	"${REMOTE}:${REMOTE_N8N_DIR}/docker-compose.oci-merge-main.yml"

"${SCP_CMD[@]}" \
	"${DEPLOY_DIR}/docker-compose.oci-merge-worker.EXAMPLE.yml" \
	"${REMOTE}:${REMOTE_N8N_DIR}/docker-compose.oci-merge-worker.yml"

echo "YAML copiados para ${REMOTE}:${REMOTE_N8N_DIR}/docker-compose.oci-merge-*.yml"

if [[ "${SKIP_UP:-0}" == "1" ]]; then
	echo "SKIP_UP=1 — não a correr docker compose up."
	exit 0
fi

"${SSH_CMD[@]}" "cd '${REMOTE_N8N_DIR}' && docker compose \
	-f docker-compose-main.yml -f docker-compose.oci-merge-main.yml \
	-f docker-compose-worker.yml -f docker-compose.oci-merge-worker.yml \
	up -d"

echo "Compose up concluído. Reinstala community nodes (Evolution, Chatwoot) na UI se node_modules estava vazio."
