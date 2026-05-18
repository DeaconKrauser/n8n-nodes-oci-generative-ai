# n8n-nodes-oci-generative-ai

[![npm version](https://img.shields.io/npm/v/n8n-nodes-oci-generative-ai.svg)](https://www.npmjs.com/package/n8n-nodes-oci-generative-ai)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Idioma:** [English](README.md) | Português

---

### O que é isso?

Um nó community para [n8n](https://n8n.io) que conecta o **Oracle Cloud Infrastructure (OCI) Generative AI** como modelo de chat LLM nativo. Ele se encaixa diretamente no **AI Agent**, em cadeias LangChain e em qualquer nó que aceite um sub-nó de Language Model — da mesma forma que se usam os nós do OpenAI, Anthropic ou Google Gemini.

### Por que usar em vez de um nó HTTP genérico?

| Recurso | Nó HTTP Genérico | Este nó |
|---|---|---|
| Funciona como LLM do AI Agent | Não | **Sim** |
| Suporte a tool calling | Não | **Sim** |
| Integração com memória LangChain | Não | **Sim** |
| Saída em streaming | Não | **Sim** |
| Gerenciador de credenciais nativo | Headers manuais | **Sim** |

### Regiões e modelos suportados

| Região | Base URL |
|---|---|
| Brazil East (São Paulo) | `https://inference.generativeai.sa-saopaulo-1.oci.oraclecloud.com/20231130/actions` |
| US Midwest (Chicago) | `https://inference.generativeai.us-chicago-1.oci.oraclecloud.com/20231130/actions` |
| Germany Central (Frankfurt) | `https://inference.generativeai.eu-frankfurt-1.oci.oraclecloud.com/20231130/actions` |
| UK South (London) | `https://inference.generativeai.uk-london-1.oci.oraclecloud.com/20231130/actions` |

Disponibilidade de modelos varia por região. Exemplos:
- **São Paulo**: `meta.llama-3.1-8b-instruct`, `meta.llama-3.1-70b-instruct`, `cohere.command-r-plus`
- **Chicago**: `meta.llama-3.3-70b-instruct`, `google.gemini-2.5-flash`, `cohere.command-a-03-2025`

Consulte a [documentação do OCI Generative AI](https://docs.oracle.com/iaas/Content/generative-ai/overview.htm) para a lista completa de modelos por região.

### Instalação

**Via Community Nodes do n8n (recomendado)**

1. No seu n8n, acesse **Settings → Community Nodes**
2. Clique em **Install**
3. Digite `n8n-nodes-oci-generative-ai`
4. Clique em **Install**

> Requer n8n v1.0.0 ou superior com community nodes habilitados.

**Via npm (self-hosted / Docker)**

```bash
npm install n8n-nodes-oci-generative-ai
```

Defina a variável de ambiente para o n8n carregar o pacote:

```
N8N_CUSTOM_EXTENSIONS=n8n-nodes-oci-generative-ai
```

### Configuração

**Credenciais** — crie uma nova credencial **Oracle OCI Generative AI Inference API**:

| Campo | Descrição |
|---|---|
| **Base URL** | Endpoint de inferência OCI para a sua região (veja tabela acima) |
| **Bearer Token** | Seu token de autenticação OCI |
| **Test Model** | Modelo usado apenas para testar a conexão da credencial (padrão: `meta.llama-3.1-8b-instruct`) |

**Parâmetros do nó:**

| Parâmetro | Descrição |
|---|---|
| **Model** | ID do modelo a usar (ex.: `meta.llama-3.1-70b-instruct`) |
| **Temperature** | Controle de aleatoriedade (0 = determinístico, 1 = criativo) |
| **Max Tokens** | Número máximo de tokens na resposta |
| **Top P** | Parâmetro de nucleus sampling |
| **Response Format** | `Default` (texto) ou `JSON Object` (força saída JSON) |

### Como usar

1. Adicione um nó **AI Agent** ao seu workflow
2. Conecte o **OCI Generative AI Chat Model** como sub-nó de Language Model
3. *(Opcional)* Conecte um nó de **Memória** (ex.: Postgres Chat Memory) para histórico de conversa
4. *(Opcional)* Adicione sub-nós de **Tools** (HTTP Request, Code, etc.) para comportamento agêntico

### Requisitos

- n8n >= 1.0.0
- Conta Oracle Cloud Infrastructure ativa com o serviço Generative AI habilitado
- Bearer Token OCI válido para a API de inferência

---

## Licença

[MIT](LICENSE)
