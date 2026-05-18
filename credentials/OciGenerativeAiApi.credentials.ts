import type {
	IAuthenticateGeneric,
	ICredentialTestRequest,
	ICredentialType,
	Icon,
	INodeProperties,
} from "n8n-workflow";

/**
 * Credencial HTTP Bearer para a API OpenAI-compatible de inferência OCI Generative AI.
 */
export class OciGenerativeAiApi implements ICredentialType {
	name = "ociGenerativeAiApi";

	displayName = "Oracle OCI Generative AI Inference API";

	icon: Icon = "file:ociGenAiApi.svg";

	documentationUrl =
		"https://docs.oracle.com/iaas/Content/generative-ai/overview.htm";

	properties: INodeProperties[] = [
		{
			displayName: "Base URL",
			name: "baseUrl",
			type: "string",
			default:
				"https://inference.generativeai.sa-saopaulo-1.oci.oraclecloud.com/20231130/actions",
			placeholder:
				"https://inference.generativeai.REGION.oci.oraclecloud.com/20231130/actions",
			description:
				"URL até o prefixo …/actions (sem barra final). O nó chama POST {baseUrl}/v1/chat/completions.",
			required: true,
		},
		{
			displayName: "Bearer Token",
			name: "bearerToken",
			type: "string",
			typeOptions: {
				password: true,
			},
			default: "",
			required: true,
			description: "Token enviado em Authorization: Bearer …",
		},
		{
			displayName: "Test Model",
			name: "testModel",
			type: "string",
			default: "meta.llama-3.1-8b-instruct",
			description: "Modelo usado apenas para testar a conexão da credencial. Usa um modelo disponível na tua região (ex.: meta.llama-3.1-8b-instruct para São Paulo, google.gemini-2.5-flash para Chicago).",
		},
	];

	authenticate: IAuthenticateGeneric = {
		type: "generic",
		properties: {
			headers: {
				Authorization: "=Bearer {{$credentials.bearerToken}}",
			},
		},
	};

	test: ICredentialTestRequest = {
		request: {
			baseURL: "={{$credentials.baseUrl}}",
			url: "/v1/chat/completions",
			method: "POST",
			headers: {
				"Content-Type": "application/json",
			},
			body: {
				model: "={{$credentials.testModel}}",
				messages: [{ role: "user", content: "." }],
				max_tokens: 1,
				temperature: 0,
			},
			json: true,
		},
	};
}
