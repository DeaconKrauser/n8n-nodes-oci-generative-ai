================================================================================
Deploy seguro do n8n-nodes-oci-generative-ai (só aditivo)
================================================================================

Princípios
---------
1. Não editar os ficheiros docker-compose-main.yml / docker-compose-worker.yml
   que já estão em produção. Usar um FICHEIRO EXTRA de merge (ver exemplos YAML).
2. O pacote fica só em:
   /home/ubuntu/n8n/custom-extensions/n8n-nodes-oci-generative-ai
   Nada disso substitui ~/.n8n nem apaga o resto de ~/n8n.
3. O script deploy-via-ssh.sh por defeito NÃO usa rsync --delete (não apaga no
   servidor ficheiros antigos que já não existam no PC). Para espelho exacto:
   RSYNC_DELETE=1

O que NÃO mexe nos teus dados n8n
---------------------------------
- ~/.n8n no host pode nem existir (dados muitas vezes só dentro do contentor).
- O volume novo monta APENAS a pasta do pacote custom; não monta por cima da
  pasta de dados do n8n a menos que configures mal outro volume.

Passos no servidor (uma vez)
-----------------------------
1) Copiar os exemplos de merge para ~/n8n e renomear (ou criar à mão):

   cp deploy/docker-compose.oci-merge-main.EXAMPLE.yml \
      ~/n8n/docker-compose.oci-merge-main.yml
   cp deploy/docker-compose.oci-merge-worker.EXAMPLE.yml \
      ~/n8n/docker-compose.oci-merge-worker.yml

2) Abrir cada ficheiro e substituir o nome do serviço em "services:"
   pelo nome REAL que aparece no teu compose (ex.: n8n, app, worker).

3) Validar YAML sem subir nada (detecta erros de sintaxe):

   cd ~/n8n
   docker compose -f docker-compose-main.yml -f docker-compose.oci-merge-main.yml config > /tmp/n8n-main-resolvido.yml
   docker compose -f docker-compose-worker.yml -f docker-compose.oci-merge-worker.yml config > /tmp/n8n-worker-resolvido.yml

   Se o segundo "config" falhar com: service "n8n" has neither an image nor a build context,
   o worker.yml provavelmente tem um serviço "n8n" incompleto (só overrides). Ver
   deploy/ACTIVAR-NO-SERVIDOR.txt (grep em docker-compose-worker.yml) ou validar com
   main+worker+merge no mesmo comando:

   docker compose -f docker-compose-main.yml -f docker-compose-worker.yml -f docker-compose.oci-merge-worker.yml config > /tmp/n8n-worker-resolvido.yml

4) Subir com merge (só acrescenta env + volume ao serviço que escolheste):

   docker compose -f docker-compose-main.yml -f docker-compose.oci-merge-main.yml up -d
   docker compose -f docker-compose-worker.yml -f docker-compose.oci-merge-worker.yml up -d

Se algo correr mal
-----------------
- Voltar ao compose antigo SEM o ficheiro -f extra:
  docker compose -f docker-compose-main.yml up -d
  (idem worker)
- O ficheiro de merge pode apagar-se ou renomear para .disabled.

Deploy do código (no PC de desenvolvimento)
--------------------------------------------
  cd .../n8n-nodes-oci-generative-ai
  SSHPASS='...' USE_DOCKER_BUILD=1 \
    ./scripts/deploy-via-ssh.sh ubuntu@IP:/home/ubuntu/n8n/custom-extensions/n8n-nodes-oci-generative-ai

O build em Docker usa Node 22 + apt (python3, make, g++) para compilar dependências nativas
(isolated-vm do @n8n/node-cli). Imagem alternativa: DOCKER_BUILD_IMAGE=node:22-bookworm

Depois no servidor: reiniciar os contentores n8n (para recarregar extensões).

Erro "Unrecognized node type: CUSTOM.lmChatOciGenAi" ao executar
---------------------------------------------------------------
1) No merge, use volume + N8N_CUSTOM_EXTENSIONS em
   /home/node/.n8n/custom/n8n-nodes-oci-generative-ai (ver EXAMPLE.yml no repo).
2) Se EXECUTIONS_MODE=queue, o *worker* n8n também precisa do mesmo volume e env
   (docker compose -f docker-compose-worker.yml ...). Sem isso, a UI mostra o nó
   mas a execução falha com "Unrecognized node type".
3) Se N8N_CUSTOM_EXTENSIONS tiver vários caminhos separados por ";", existe um bug
   conhecido no n8n: todos os pacotes "custom" partilham o nome interno CUSTOM e
   só o *último* caminho na lista fica registado. Coloque o path do OCI por último
   ou use um único caminho para extensões custom.

Falha npm "isolated-vm" / Python / node-gyp
-------------------------------------------
Se vir erro de Python ou isolated-vm no passo Docker, atualize o script deploy-via-ssh.sh
(do repositório) e volte a correr o deploy; ou no servidor com Node instalado:
  cd /home/ubuntu/n8n/custom-extensions/n8n-nodes-oci-generative-ai && npm ci && npm run build
  (sem USE_DOCKER_BUILD, desde que o host tenha Node 22+ e build-essential.)
