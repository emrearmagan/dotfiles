/**
 * Ollama Provider Extension
 *
 * Registers your remote Ollama server as the "ollama" provider with all models
 * it serves. Skipped when OLLAMA_REMOTE_HOST is unset or the server doesn't answer
 * within 200ms, so pi starts normally without it. When the server is set but
 * can't be used, pi shows a warning with the reason.
 *
 * Usage:
 *   /model ollama/<model>
 *
 * Environment:
 *   OLLAMA_REMOTE_HOST   Ollama server, e.g. https://ollama.example.com
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const OLLAMA_REMOTE_HOST = process.env.OLLAMA_REMOTE_HOST;
const OLLAMA_BASE_URL = OLLAMA_REMOTE_HOST && `${OLLAMA_REMOTE_HOST}/v1`;
const FETCH_TIMEOUT_MS = 200;

// pi waits for this before startup, so ollama models work as the default model
export default async function (pi: ExtensionAPI) {
  const error = await registerOllamaProvider(pi);
  if (!error) return;

  pi.on("session_start", async (_event, ctx) => {
    if (ctx.hasUI) ctx.ui.notify(`Ollama: ${error}`, "warning");
  });
}

// Returns why the provider wasn't registered, or nothing when it was or Ollama isn't set up
async function registerOllamaProvider(
  pi: ExtensionAPI,
): Promise<string | undefined> {
  if (!OLLAMA_BASE_URL) return;

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);
  try {
    const response = await fetch(`${OLLAMA_BASE_URL}/models`, {
      signal: controller.signal,
    });

    if (!response.ok) return `server answered with ${response.status}`;

    const payload = (await response.json()) as {
      data?: Array<{
        id?: string;
        name?: string;
        context_window?: number;
        max_tokens?: number;
      }>;
    };

    const models = (payload.data ?? [])
      .filter(
        (
          model,
        ): model is {
          id: string;
          name?: string;
          context_window?: number;
          max_tokens?: number;
        } => typeof model.id === "string" && model.id.length > 0,
      )
      .map((model) => ({
        id: model.id,
        name: model.name ?? model.id,
        reasoning: false,
        input: ["text"],
        contextWindow: model.context_window ?? 128000,
        maxTokens: model.max_tokens ?? 4096,
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
      }));

    if (models.length === 0) return "server has no models";

    pi.registerProvider("ollama", {
      name: "Ollama (remote)",
      baseUrl: OLLAMA_BASE_URL,
      api: "openai-completions",
      apiKey: "ollama",
      compat: {
        supportsDeveloperRole: false,
        supportsReasoningEffort: false,
      },
      models,
    });
  } catch {
    return controller.signal.aborted
      ? `server didn't answer within ${FETCH_TIMEOUT_MS}ms`
      : "server not reachable";
  } finally {
    clearTimeout(timeout);
  }
}
