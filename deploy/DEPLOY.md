# Deploy Guide / Guia de Deploy

**Language / Idioma:** [English](#english) | [Português](#português)

---

## English

### Requirements
- Docker + Docker Compose running on the server
- The package built locally: `npm ci && npm run build`
- SSH access to the server

### 1. Send files to the server

```bash
./scripts/deploy-via-ssh.sh ubuntu@YOUR_VPS_IP:/home/ubuntu/n8n/custom-extensions/n8n-nodes-oci-generative-ai
```

### 2. Find your service name

On the server, check the exact service name used in your compose file:

```bash
docker compose -f docker-compose-main.yml config --services
```

Open `docker-compose.oci-merge-main.yml` and replace `n8n_main` with the name returned above. Do the same for `docker-compose.oci-merge-worker.yml` with the worker service name.

### 3. Create the data directory (first time only)

```bash
mkdir -p /home/ubuntu/n8n/data
sudo chown -R 1000:1000 /home/ubuntu/n8n/data
```

### 4. Apply the merge and restart

```bash
docker compose -f docker-compose-main.yml -f docker-compose.oci-merge-main.yml up -d
docker compose -f docker-compose-worker.yml -f docker-compose.oci-merge-worker.yml up -d
```

> If the second command fails with `service "n8n" has neither an image`, include the main file too:
> ```bash
> docker compose -f docker-compose-main.yml -f docker-compose-worker.yml -f docker-compose.oci-merge-worker.yml up -d
> ```

### 5. Verify

In the n8n UI, search for **Oracle OCI** — the node should appear under Language Models.

### Rollback

Remove the `-f docker-compose.oci-merge-*.yml` flags and run `up -d` again with only the original files.

### Common errors

| Error | Cause | Fix |
|---|---|---|
| `Unrecognized node type: CUSTOM.lmChatOciGenAi` | Worker missing the extension | Apply the worker merge file too |
| `service "n8n" has neither an image` | Wrong service name in merge file | Run `config --services` and update the key |
| Node not appearing in UI | `dist/` not present | Run `npm ci && npm run build` locally first |

---

## Português

### Requisitos
- Docker + Docker Compose rodando no servidor
- Pacote compilado localmente: `npm ci && npm run build`
- Acesso SSH ao servidor

### 1. Enviar os arquivos para o servidor

```bash
./scripts/deploy-via-ssh.sh ubuntu@SEU_IP_VPS:/home/ubuntu/n8n/custom-extensions/n8n-nodes-oci-generative-ai
```

### 2. Descobrir o nome do serviço

No servidor, verifique o nome exato do serviço no seu compose:

```bash
docker compose -f docker-compose-main.yml config --services
```

Abra `docker-compose.oci-merge-main.yml` e substitua `n8n_main` pelo nome retornado. Faça o mesmo em `docker-compose.oci-merge-worker.yml` com o nome do serviço worker.

### 3. Criar o diretório de dados (apenas na primeira vez)

```bash
mkdir -p /home/ubuntu/n8n/data
sudo chown -R 1000:1000 /home/ubuntu/n8n/data
```

### 4. Aplicar o merge e reiniciar

```bash
docker compose -f docker-compose-main.yml -f docker-compose.oci-merge-main.yml up -d
docker compose -f docker-compose-worker.yml -f docker-compose.oci-merge-worker.yml up -d
```

> Se o segundo comando falhar com `service "n8n" has neither an image`, inclua o main também:
> ```bash
> docker compose -f docker-compose-main.yml -f docker-compose-worker.yml -f docker-compose.oci-merge-worker.yml up -d
> ```

### 5. Verificar

Na UI do n8n, pesquise por **Oracle OCI** — o nó deve aparecer em Language Models.

### Reverter

Remova os flags `-f docker-compose.oci-merge-*.yml` e rode `up -d` novamente com apenas os arquivos originais.

### Erros comuns

| Erro | Causa | Solução |
|---|---|---|
| `Unrecognized node type: CUSTOM.lmChatOciGenAi` | Worker sem a extensão | Aplicar o merge do worker também |
| `service "n8n" has neither an image` | Nome de serviço errado no merge | Rodar `config --services` e corrigir a chave |
| Nó não aparece na UI | `dist/` ausente | Rodar `npm ci && npm run build` localmente primeiro |
