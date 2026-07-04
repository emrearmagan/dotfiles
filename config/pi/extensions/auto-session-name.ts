/**
 * Auto Session Name Extension
 *
 * Names new pi sessions from the first user prompt. Uses the configured pi
 * model when possible, then falls back to a simple prompt-derived title.
 *
 * Usage:
 *   /auto-session-name              Regenerate from the first user prompt
 *   /auto-session-name <text>       Generate from explicit text
 *
 * Environment:
 *   PI_AUTO_SESSION_NAME=0          Disable automatic naming
 *   PI_AUTO_SESSION_NAME_NOTIFY=0   Hide notifications
 *   PI_AUTO_SESSION_NAME_PROVIDER   Override naming provider
 *   PI_AUTO_SESSION_NAME_MODEL      Override naming model
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { completeSimple, type AssistantMessage, type Model } from "@earendil-works/pi-ai/compat";

const MAX_PROMPT_CHARS = 2500;
const MAX_TITLE_CHARS = 60;
const REQUEST_TIMEOUT_MS = 5000;

export default function (pi: ExtensionAPI) {
	let hadUserPromptAtSessionStart = false;
	let namedThisRuntime = false;
	let warnedMissingProvider = false;

	const reconstructState = (ctx: ExtensionContext) => {
		const entries = ctx.sessionManager.getBranch();
		hadUserPromptAtSessionStart = entries.some(
			(entry) => entry.type === "message" && entry.message.role === "user",
		);
		namedThisRuntime = false;
	};

	pi.on("session_start", async (_event, ctx) => reconstructState(ctx));
	pi.on("session_tree", async (_event, ctx) => reconstructState(ctx));

	pi.registerCommand("auto-session-name", {
		description: "Regenerate the session name from the first user prompt (or provided text)",
		handler: async (args, ctx) => {
			const prompt = args.trim() || getFirstUserPrompt(ctx);
			if (!prompt) {
				ctx.ui.notify("Auto session naming: no user prompt found.", "warning");
				return;
			}

			ctx.ui.notify("Generating session name…", "info");
			const title = await generateTitle(prompt, ctx);
			if (!title) {
				ctx.ui.notify("Auto session naming: failed to generate title.", "warning");
				return;
			}

			pi.setSessionName(title);
			ctx.ui.notify(`Session named: ${title}`, "info");
		},
	});

	pi.on("before_agent_start", (event, ctx) => {
		if (process.env.PI_AUTO_SESSION_NAME === "0") return;
		if (namedThisRuntime) return;
		if (hadUserPromptAtSessionStart) return;
		if (pi.getSessionName()) return;

		namedThisRuntime = true;

		void (async () => {
			if (process.env.PI_AUTO_SESSION_NAME_NOTIFY !== "0") {
				ctx.ui.notify("Generating session name…", "info");
			}

			const title = await generateTitle(event.prompt, ctx);
			if (!title) {
				if (process.env.PI_AUTO_SESSION_NAME_NOTIFY !== "0") {
					ctx.ui.notify("Auto session naming: failed to generate title.", "warning");
				}
				return;
			}
			if (pi.getSessionName()) return;

			pi.setSessionName(title);
			if (process.env.PI_AUTO_SESSION_NAME_NOTIFY !== "0") {
				ctx.ui.notify(`Session named: ${title}`, "info");
			}
		})();
	});

	async function generateTitle(prompt: string, ctx: ExtensionContext): Promise<string | undefined> {
		const fromPiProvider = await generateTitleWithPiProvider(prompt, ctx);
		if (fromPiProvider) return fromPiProvider;

		return fallbackTitle(prompt);
	}

	async function generateTitleWithPiProvider(prompt: string, ctx: ExtensionContext): Promise<string | undefined> {
		const model = getNamingModel(ctx);
		if (!model) {
			if (!warnedMissingProvider && process.env.PI_AUTO_SESSION_NAME_NOTIFY === "1") {
				ctx.ui.notify("Auto session naming: no configured pi model found, using fallback title.", "warning");
				warnedMissingProvider = true;
			}
			return undefined;
		}

		const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
		if (!auth.ok) return undefined;

		const controller = new AbortController();
		const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

		try {
			const message = await completeSimple(
				model,
				{
					systemPrompt:
						"Create a short, descriptive coding-agent session title from the user's first prompt. Return only the title. No quotes. Max 6 words. Prefer imperative/noun phrase style.",
					messages: [
						{
							role: "user",
							content: prompt.slice(0, MAX_PROMPT_CHARS),
							timestamp: Date.now(),
						},
					],
				},
				{
					apiKey: auth.apiKey,
					headers: auth.headers,
					env: auth.env,
					maxTokens: 32,
					reasoning: "minimal",
					signal: controller.signal,
				},
			);

			return sanitizeTitle(extractAssistantText(message));
		} catch {
			return undefined;
		} finally {
			clearTimeout(timeout);
		}
	}
}

function getFirstUserPrompt(ctx: ExtensionContext): string | undefined {
	for (const entry of ctx.sessionManager.getBranch()) {
		if (entry.type === "message" && entry.message.role === "user") {
			const content = entry.message.content;
			return typeof content === "string"
				? content
				: content
						.filter((item) => item.type === "text")
						.map((item) => item.text)
						.join(" ");
		}
	}

	return undefined;
}

function getNamingModel(ctx: ExtensionContext): Model<any> | undefined {
	const provider = process.env.PI_AUTO_SESSION_NAME_PROVIDER;
	const modelId = process.env.PI_AUTO_SESSION_NAME_MODEL;
	if (provider && modelId) return ctx.modelRegistry.find(provider, modelId);

	// Keep the naming call on the user's configured auth/provider, but prefer a
	// cheaper Codex model when available instead of spending the main model on it.
	if (ctx.model?.provider === "openai-codex") {
		return ctx.modelRegistry.find("openai-codex", modelId ?? "gpt-5.4-mini") ?? ctx.model;
	}

	return ctx.model;
}

function extractAssistantText(message: AssistantMessage): string | undefined {
	return message.content
		.filter((content) => content.type === "text")
		.map((content) => content.text)
		.join(" ");
}

function sanitizeTitle(value: string | undefined): string | undefined {
	const title = value
		?.replace(/[\r\n]+/g, " ")
		.replace(/^['"`“”‘’]+|['"`“”‘’]+$/g, "")
		.replace(/\s+/g, " ")
		.trim();

	if (!title) return undefined;

	return title.length <= MAX_TITLE_CHARS ? title : `${title.slice(0, MAX_TITLE_CHARS - 1).trim()}…`;
}

function fallbackTitle(prompt: string): string | undefined {
	const cleaned = prompt
		.replace(/```[\s\S]*?```/g, " ")
		.replace(/https?:\/\/\S+/g, " ")
		.replace(/[^\p{L}\p{N}\s_-]/gu, " ")
		.replace(/\s+/g, " ")
		.trim();

	if (!cleaned) return undefined;

	const words = cleaned.split(" ").slice(0, 6).join(" ");
	return sanitizeTitle(words);
}
