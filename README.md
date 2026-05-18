# n8n-nodes-oci-generative-ai

[![npm version](https://img.shields.io/npm/v/n8n-nodes-oci-generative-ai.svg)](https://www.npmjs.com/package/n8n-nodes-oci-generative-ai)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Language:** English | [Português](README.pt-BR.md)

---

### What is this?

A community node for [n8n](https://n8n.io) that connects **Oracle Cloud Infrastructure (OCI) Generative AI** as a native LLM chat model. It plugs directly into the **AI Agent**, **LangChain chains**, and any node that accepts a Language Model sub-node — the same way you use OpenAI, Anthropic, or Google Gemini nodes.

### Why use this instead of a generic HTTP node?

| Feature | Generic HTTP Node | This node |
|---|---|---|
| Works as AI Agent LLM | No | **Yes** |
| Tool calling support | No | **Yes** |
| LangChain memory integration | No | **Yes** |
| Streaming output | No | **Yes** |
| Built-in credential manager | Manual headers | **Yes** |

### Supported regions & models

| Region | Base URL |
|---|---|
| Brazil East (São Paulo) | `https://inference.generativeai.sa-saopaulo-1.oci.oraclecloud.com/20231130/actions` |
| US Midwest (Chicago) | `https://inference.generativeai.us-chicago-1.oci.oraclecloud.com/20231130/actions` |
| Germany Central (Frankfurt) | `https://inference.generativeai.eu-frankfurt-1.oci.oraclecloud.com/20231130/actions` |
| UK South (London) | `https://inference.generativeai.uk-london-1.oci.oraclecloud.com/20231130/actions` |

Model availability varies by region. Examples:
- **São Paulo**: `meta.llama-3.1-8b-instruct`, `meta.llama-3.1-70b-instruct`, `cohere.command-r-plus`
- **Chicago**: `meta.llama-3.3-70b-instruct`, `google.gemini-2.5-flash`, `cohere.command-a-03-2025`

See the [OCI Generative AI documentation](https://docs.oracle.com/iaas/Content/generative-ai/overview.htm) for the full model list per region.

### Installation

**Via n8n Community Nodes (recommended)**

1. Go to **Settings → Community Nodes** in your n8n instance
2. Click **Install**
3. Enter `n8n-nodes-oci-generative-ai`
4. Click **Install**

> Requires n8n v1.0.0 or later with community nodes enabled.

**Via npm (self-hosted / Docker)**

```bash
npm install n8n-nodes-oci-generative-ai
```

Set the environment variable so n8n loads the package:

```
N8N_CUSTOM_EXTENSIONS=n8n-nodes-oci-generative-ai
```

### Configuration

**Credentials** — create a new **Oracle OCI Generative AI Inference API** credential:

| Field | Description |
|---|---|
| **Base URL** | OCI inference endpoint for your region (see table above) |
| **Bearer Token** | Your OCI authentication token |
| **Test Model** | Model used only for the credential connection test (default: `meta.llama-3.1-8b-instruct`) |

**Node parameters:**

| Parameter | Description |
|---|---|
| **Model** | Model ID to use (e.g. `meta.llama-3.1-70b-instruct`) |
| **Temperature** | Randomness control (0 = deterministic, 1 = creative) |
| **Max Tokens** | Maximum tokens in the response |
| **Top P** | Nucleus sampling parameter |
| **Response Format** | `Default` (text) or `JSON Object` (forces JSON output) |

### Usage

1. Add an **AI Agent** node to your workflow
2. Connect **OCI Generative AI Chat Model** as the Language Model sub-node
3. *(Optional)* Connect a **Memory** node (e.g. Postgres Chat Memory) for conversation history
4. *(Optional)* Add **Tool** sub-nodes (HTTP Request, Code, etc.) for agentic behavior

### Requirements

- n8n >= 1.0.0
- Active Oracle Cloud Infrastructure account with Generative AI service enabled
- Valid OCI Bearer Token for the inference API

---

## License

[MIT](LICENSE)
