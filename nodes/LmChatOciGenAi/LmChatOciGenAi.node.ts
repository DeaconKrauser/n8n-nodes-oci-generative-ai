import {
	NodeConnectionTypes,
	type INodeType,
	type INodeTypeDescription,
	type ISupplyDataFunctions,
	type SupplyData,
} from "n8n-workflow";

import { ChatOciGenAi } from "./ChatOciGenAi";

export class LmChatOciGenAi implements INodeType {
	description: INodeTypeDescription = {
		displayName: "Oracle OCI Generative AI Chat Model",
		name: "lmChatOciGenAi",
		icon: "file:ociGenAi.svg",
		group: ["transform"],
		version: 1,
		description: "Chat model via OCI Generative AI (OpenAI-compatible API)",
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
						url: "https://github.com/DeaconKrauser/n8n-n8n-nodes-oci-generative-ai",
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
				displayName: "Connect the output of this node to an AI Agent or chain as a language model.",
				name: "usageHint",
				type: "notice",
				default: "",
			},
			{
				displayName: "Model",
				name: "model",
				type: "string",
				default: "meta.llama-3.1-8b-instruct",
				description: "Model ID on OCI (e.g. meta.llama-3.1-70b-instruct, google.gemini-2.5-flash)",
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
