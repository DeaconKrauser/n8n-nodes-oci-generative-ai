import {
	AIMessage,
	AIMessageChunk,
	type BaseMessage,
	ToolMessage,
} from "@langchain/core/messages";
import {
	BaseChatModel,
	type BaseChatModelCallOptions,
	type BaseChatModelParams,
	type BindToolsInput,
} from "@langchain/core/language_models/chat_models";
import type { BaseLanguageModelInput } from "@langchain/core/language_models/base";
import { type CallbackManagerForLLMRun } from "@langchain/core/callbacks/manager";
import { type ChatGeneration, ChatGenerationChunk, type ChatResult } from "@langchain/core/outputs";
import type { Runnable } from "@langchain/core/runnables";
import { convertToOpenAITool } from "@langchain/core/utils/function_calling";

/**
 * Parâmetros do modelo de chat OCI (corpo alinhado à API OpenAI-compatible).
 */
export type ChatOciGenAiInput = BaseChatModelParams & {
	baseUrl: string;
	bearerToken: string;
	model: string;
	temperature?: number;
	maxTokens?: number;
	topP?: number;
	responseFormat?: "default" | "json_object";
};

type OciApiToolCall = {
	id: string;
	type: string;
	function: {
		name: string;
		arguments: string;
	};
};

type OciChatCompletionsRequest = {
	model: string;
	messages: Array<Record<string, unknown>>;
	tools?: unknown[];
	tool_choice?: unknown;
	max_tokens?: number;
	temperature?: number;
	top_p?: number;
	response_format?: { type: "json_object" } | { type: "text" };
};

type OciChatCompletionsResponse = {
	choices?: Array<{
		message?: {
			role?: string;
			content?: string | null;
			tool_calls?: OciApiToolCall[];
		};
	}>;
	error?: {
		message?: string;
		code?: string;
	};
};

function normalizeBaseUrl(baseUrl: string): string {
	return baseUrl.replace(/\/+$/, "");
}

function messageToRole(message: BaseMessage): string {
	const messageType = message.getType();
	if (messageType === "human") {
		return "user";
	}
	if (messageType === "ai") {
		return "assistant";
	}
	if (messageType === "system") {
		return "system";
	}
	if (messageType === "tool") {
		return "tool";
	}
	return "user";
}

function messageToText(message: BaseMessage): string {
	const { content } = message;
	if (typeof content === "string") {
		return content;
	}
	return JSON.stringify(content);
}

/**
 * Converte mensagens LangChain para o formato esperado pelo endpoint chat/completions (incl. tool / assistant com tool_calls).
 */
function baseMessageToOpenAI(message: BaseMessage): Record<string, unknown> {
	const kind = message.getType();
	if (kind === "ai") {
		const ai = message as AIMessage;
		const payload: Record<string, unknown> = {
			role: "assistant",
			content:
				typeof ai.content === "string"
					? ai.content
					: ai.content === null || ai.content === undefined
						? ""
						: JSON.stringify(ai.content),
		};
		if (ai.tool_calls && ai.tool_calls.length > 0) {
			payload.tool_calls = ai.tool_calls.map((tc) => ({
				id: tc.id ?? "",
				type: "function",
				function: {
					name: tc.name,
					arguments: JSON.stringify(tc.args ?? {}),
				},
			}));
		}
		return payload;
	}
	if (kind === "tool") {
		const tool = message as ToolMessage;
		return {
			role: "tool",
			tool_call_id: tool.tool_call_id,
			content: typeof tool.content === "string" ? tool.content : JSON.stringify(tool.content),
		};
	}
	return {
		role: messageToRole(message),
		content: messageToText(message),
	};
}

/**
 * Opções de invocação incluindo tools (após bindTools); alinha com o que withConfig persiste no LangChain.
 */
export type ChatOciGenAiCallOptions = BaseChatModelCallOptions & {
	tools?: unknown[];
	tool_choice?: unknown;
};

/**
 * Cliente LangChain para OCI Generative AI (OpenAI-compatible chat/completions), com bindTools para o AI Agent (Tools Agent) do n8n.
 */
export class ChatOciGenAi extends BaseChatModel<ChatOciGenAiCallOptions> {
	lc_namespace = ["n8n_nodes_oci_generative_ai", "chat_models"];

	baseUrl: string;

	bearerToken: string;

	model: string;

	temperature?: number;

	maxTokens?: number;

	topP?: number;

	responseFormat: "default" | "json_object";

	constructor(fields: ChatOciGenAiInput) {
		super(fields);
		this.baseUrl = fields.baseUrl;
		this.bearerToken = fields.bearerToken;
		this.model = fields.model;
		this.temperature = fields.temperature;
		this.maxTokens = fields.maxTokens;
		this.topP = fields.topP;
		this.responseFormat = fields.responseFormat ?? "default";
	}

	_llmType(): string {
		return "oci_generative_ai";
	}

	/**
	 * Expõe tool calling ao agente LangChain / n8n Tools Agent (validação exige esta função).
	 */
	bindTools(
		tools: BindToolsInput[],
		kwargs?: Partial<ChatOciGenAiCallOptions>,
	): Runnable<BaseLanguageModelInput, AIMessageChunk, ChatOciGenAiCallOptions> {
		const { tool_choice: toolChoice, ...rest } = kwargs ?? {};
		return this.withConfig({
			tools: tools.map((tool) => convertToOpenAITool(tool)),
			...rest,
			tool_choice: toolChoice ?? "auto",
		});
	}

	/**
	 * Chamada não-streaming à API OCI.
	 */
	async _generate(
		messages: BaseMessage[],
		parsedOptions: this["ParsedCallOptions"],
		runManager?: CallbackManagerForLLMRun,
	): Promise<ChatResult> {
		void runManager;
		const opts = parsedOptions as ChatOciGenAiCallOptions;
		const url = `${normalizeBaseUrl(this.baseUrl)}/v1/chat/completions`;
		const body: OciChatCompletionsRequest = {
			model: this.model,
			messages: messages.map((m) => baseMessageToOpenAI(m)),
			temperature: this.temperature,
			max_tokens: this.maxTokens,
			top_p: this.topP,
		};
		if (this.responseFormat === "json_object" && !(opts.tools && opts.tools.length > 0)) {
			body.response_format = { type: "json_object" };
		}
		if (opts.tools && opts.tools.length > 0) {
			body.tools = opts.tools;
			body.tool_choice = opts.tool_choice ?? "auto";
		}

		const response = await fetch(url, {
			method: "POST",
			headers: {
				Authorization: `Bearer ${this.bearerToken}`,
				"Content-Type": "application/json",
			},
			body: JSON.stringify(body),
		});

		const rawText = await response.text();
		let parsed: OciChatCompletionsResponse;
		try {
			parsed = JSON.parse(rawText) as OciChatCompletionsResponse;
		} catch {
			throw new Error(
				`Resposta não-JSON da OCI Generative AI (HTTP ${String(response.status)}): ${rawText.slice(0, 500)}`,
			);
		}

		if (!response.ok) {
			const apiMessage = parsed.error?.message ?? rawText.slice(0, 500);
			throw new Error(`OCI Generative AI HTTP ${String(response.status)}: ${apiMessage}`);
		}

		const rawMsg = parsed.choices?.[0]?.message;
		if (!rawMsg) {
			throw new Error(`Resposta sem choices[0].message: ${rawText.slice(0, 500)}`);
		}

		if (rawMsg.tool_calls && rawMsg.tool_calls.length > 0) {
			const tool_calls = rawMsg.tool_calls.map((tc) => {
				let args: Record<string, unknown> = {};
				try {
					args = JSON.parse(tc.function.arguments || "{}") as Record<string, unknown>;
				} catch {
					args = {};
				}
				return {
					name: tc.function.name,
					args,
					id: tc.id,
					type: "tool_call" as const,
				};
			});
			const content =
				rawMsg.content === null || rawMsg.content === undefined ? "" : String(rawMsg.content);
			const message = new AIMessage({
				content,
				tool_calls,
			});
			return {
				generations: [
					{
						text: content,
						message,
					},
				],
			};
		}

		const text = rawMsg.content;
		if (text === undefined || text === null) {
			throw new Error(
				`Resposta sem content nem tool_calls: ${rawText.slice(0, 500)}`,
			);
		}

		const message = new AIMessage(text);
		const generation: ChatGeneration = {
			text,
			message,
		};
		return {
			generations: [generation],
		};
	}

	/**
	 * Streaming mínimo: um chunk (texto ou tool_calls) alinhado ao resultado de _generate.
	 */
	async *_streamResponseChunks(
		messages: BaseMessage[],
		options: this["ParsedCallOptions"],
		runManager?: CallbackManagerForLLMRun,
	): AsyncGenerator<ChatGenerationChunk> {
		const result = await this._generate(messages, options, runManager);
		const first = result.generations[0];
		if (!first) {
			return;
		}
		const msg = first.message;
		if (msg.getType() === "ai") {
			const aiMsg = msg as AIMessage;
			if (aiMsg.tool_calls && aiMsg.tool_calls.length > 0) {
				const content = typeof aiMsg.content === "string" ? aiMsg.content : "";
				yield new ChatGenerationChunk({
					text: "",
					message: new AIMessageChunk({
						content,
						tool_calls: aiMsg.tool_calls,
					}),
				});
				return;
			}
		}
		const text = typeof first.text === "string" ? first.text : messageToText(first.message);
		yield new ChatGenerationChunk({
			text,
			message: new AIMessageChunk({ content: text }),
		});
	}
}
