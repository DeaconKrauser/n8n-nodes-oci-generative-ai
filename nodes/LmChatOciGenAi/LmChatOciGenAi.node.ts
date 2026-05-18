import {
	NodeConnectionTypes,
	type INodeType,
	type INodeTypeDescription,
	type ISupplyDataFunctions,
	type SupplyData,
} from "n8n-workflow";

import { ChatOciGenAi } from "./ChatOciGenAi";

/**
 * Sub-nó de language model para ligar ao AI Agent / chains LangChain no n8n.
 */
export class LmChatOciGenAi implements INodeType {
	description: INodeTypeDescription = {
		displayName: "Oracle OCI Generative AI Chat Model",
		name: "lmChatOciGenAi",
		icon: "file:ociGenAi.svg",
		group: ["transform"],
		version: 1,
		description: "Modelo de chat via OCI Generative AI (API compatível com OpenAI)",
		defaults: {
			name: "Oracle OCI GenAI Chat Model",
		},
		usableAsTool: true,
		codex: {
			categories: ["AI"],
			subcategories: {
				AI: ["Language Models", "Root Nodes"],
				"Language Models": ["Chat Models (Recommended)"],
			},
			resources: {
				primaryDocumentation: [
					{
						url: "https://github.com/",
					},
				],
			},
		},
		inputs: [],
		outputs: [NodeConnectionTypes.AiLanguageModel],
		outputNames: ["Model"],
		credentials: [
			{
				name: "ociGenerativeAiApi",
				required: true,
			},
		],
		properties: [
			{
				displayName:
					"Ligue a saída deste nó a um AI Agent (ou chain) como modelo de linguagem.",
				name: "usageHint",
				type: "notice",
				default: "",
			},
			{
				displayName: "Model",
				name: "model",
				type: "string",
				default: "google.gemini-2.5-flash",
				description: "Identificador do modelo na OCI (ex.: google.gemini-2.5-flash)",
			},
			{
				displayName: "Options",
				name: "options",
				type: "collection",
				placeholder: "Add option",
				default: {},
				options: [
					{
						displayName: "Temperature",
						name: "temperature",
						type: "number",
						typeOptions: {
							minValue: 0,
							maxValue: 2,
							numberPrecision: 2,
						},
						default: 0,
					},
					{
						displayName: "Max Tokens",
						name: "maxTokens",
						type: "number",
						typeOptions: {
							minValue: 1,
						},
						default: 4096,
					},
					{
						displayName: "Top P",
						name: "topP",
						type: "number",
						typeOptions: {
							minValue: 0,
							maxValue: 1,
							numberPrecision: 4,
						},
						default: 1,
					},
					{
						displayName: "Response Format",
						name: "responseFormat",
						type: "options",
						default: "default",
						options: [
							{
								name: "Default",
								value: "default",
							},
							{
								name: "JSON Object",
								value: "json_object",
							},
						],
					},
				],
			},
		],
	};

	async supplyData(this: ISupplyDataFunctions, itemIndex: number): Promise<SupplyData> {
		const credentials = await this.getCredentials("ociGenerativeAiApi");
		const modelName = this.getNodeParameter("model", itemIndex) as string;
		const options = this.getNodeParameter("options", itemIndex, {}) as {
			temperature?: number;
			maxTokens?: number;
			topP?: number;
			responseFormat?: "default" | "json_object";
		};

		const baseUrl = credentials.baseUrl as string;
		const bearerToken = credentials.bearerToken as string;

		const model = new ChatOciGenAi({
			baseUrl,
			bearerToken,
			model: modelName,
			temperature: options.temperature,
			maxTokens: options.maxTokens,
			topP: options.topP,
			responseFormat: options.responseFormat ?? "default",
		});

		return {
			response: model,
		};
	}
}
