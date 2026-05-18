import type {
	IAuthenticateGeneric,
	ICredentialTestRequest,
	ICredentialType,
	Icon,
	INodeProperties,
} from "n8n-workflow";

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
				"Endpoint up to the …/actions prefix (no trailing slash). The node calls POST {baseUrl}/v1/chat/completions.",
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
			description: "Token sent in Authorization: Bearer …",
		},
		{
			displayName: "Test Model",
			name: "testModel",
			type: "string",
			default: "meta.llama-3.1-8b-instruct",
			description: "Model used only for the credential connection test. Use a model available in your region (e.g. meta.llama-3.1-8b-instruct for São Paulo, google.gemini-2.5-flash for Chicago).",
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
