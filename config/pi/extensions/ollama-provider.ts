import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const OLLAMA_BASE_URL = "https://ollama.local.emrearmagan.dev/v1";
const FETCH_TIMEOUT_MS = 200;

export default function (pi: ExtensionAPI) {
  void registerOllamaProvider(pi);
}

async function registerOllamaProvider(pi: ExtensionAPI): Promise<void> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);
  try {
    const response = await fetch(`${OLLAMA_BASE_URL}/models`, {
      signal: controller.signal,
    });

    if (!response.ok) return;

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

    if (models.length === 0) return;

    pi.registerProvider("ollama", {
      name: "Ollama (local)",
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
    // Ollama is optional. If it is unavailable, skip registering the provider.
  } finally {
    clearTimeout(timeout);
  }
}
