/**
 * Auto Session Name Extension
 *
 * Names a saved pi session after its first prompt and renames it every
 * PI_AUTO_SESSION_NAME_INTERVAL user messages, as long as it still has the
 * name this extension gave it. A name you set yourself is kept. Titles come
 * from a small model call, or from the prompt's first words when that fails.
 *
 * Usage:
 *   /auto-session-name   Rename the session from the recent conversation
 *
 * Environment:
 *   PI_AUTO_SESSION_NAME=0          Disable automatic naming
 *   PI_AUTO_SESSION_NAME_INTERVAL   User messages between renames (default: 20, 0 disables)
 *   PI_AUTO_SESSION_NAME_PROVIDER   Naming provider, used with PI_AUTO_SESSION_NAME_MODEL
 *   PI_AUTO_SESSION_NAME_MODEL      Naming model, used with PI_AUTO_SESSION_NAME_PROVIDER
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { completeSimple, type Model } from "@earendil-works/pi-ai/compat";

const ENABLED = process.env.PI_AUTO_SESSION_NAME !== "0";
const INTERVAL = Number(process.env.PI_AUTO_SESSION_NAME_INTERVAL || 20);
const MAX_PROMPT_CHARS = 2500;
const MAX_SECTION_CHARS = 1200;
const MAX_TITLE_CHARS = 60;
const REQUEST_TIMEOUT_MS = 5000;

export default function (pi: ExtensionAPI) {
  // The last name this extension set. Any other name was set by you.
  let autoName: string | undefined;
  let namedAt = 0;

  const rename = async (ctx: ExtensionContext, firstPrompt?: string) => {
    const prompt = conversation(ctx, firstPrompt);
    if (!prompt) return undefined;
    const title = (await generateTitle(prompt, ctx)) ?? fallbackTitle(prompt);
    if (!title) return undefined;
    pi.setSessionName(title);
    autoName = title;
    namedAt = countUserMessages(ctx);
    return title;
  };

  // Sessions started with --no-session are never saved, so naming them is wasted
  const automatic = (ctx: ExtensionContext) =>
    ENABLED && ctx.sessionManager.getSessionFile() !== undefined;

  pi.on("session_start", async (_event, ctx) => {
    autoName = undefined;
    namedAt = countUserMessages(ctx);
  });
  pi.on("session_tree", async (_event, ctx) => {
    namedAt = countUserMessages(ctx);
  });

  pi.on("before_agent_start", (event, ctx) => {
    if (!automatic(ctx) || pi.getSessionName()) return;
    void rename(ctx, event.messageType === "user" ? event.prompt : undefined);
  });

  pi.on("agent_settled", async (_event, ctx) => {
    if (!automatic(ctx) || INTERVAL <= 0) return;
    if (pi.getSessionName() !== autoName) return;
    if (countUserMessages(ctx) - namedAt < INTERVAL) return;
    await rename(ctx);
  });

  pi.registerCommand("auto-session-name", {
    description: "Rename the session from the recent conversation",
    handler: async (_args, ctx) => {
      ctx.ui.notify("Generating session name…", "info");
      const title = await rename(ctx);
      if (title) ctx.ui.notify(`Session named: ${title}`, "info");
      else
        ctx.ui.notify("Auto session naming: nothing to name yet.", "warning");
    },
  });
}

async function generateTitle(
  prompt: string,
  ctx: ExtensionContext,
): Promise<string | undefined> {
  const model = namingModel(ctx);
  if (!model) return undefined;
  const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
  if (!auth.ok) return undefined;

  try {
    const message = await completeSimple(
      model,
      {
        systemPrompt:
          "Create a short, descriptive coding-agent session title from the recent user/assistant conversation. Return only the title. No quotes. Max 6 words. Prefer imperative/noun phrase style.",
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
        signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
      },
    );
    return sanitizeTitle(textOf(message.content));
  } catch {
    return undefined;
  }
}

function namingModel(ctx: ExtensionContext): Model<any> | undefined {
  const provider = process.env.PI_AUTO_SESSION_NAME_PROVIDER;
  const id = process.env.PI_AUTO_SESSION_NAME_MODEL;
  if (provider && id) return ctx.modelRegistry.find(provider, id);
  // Naming doesn't need the main model; use a cheaper Codex one when it exists
  if (ctx.model?.provider === "openai-codex") {
    return ctx.modelRegistry.find("openai-codex", "gpt-5.6-luna") ?? ctx.model;
  }
  return ctx.model;
}

function conversation(
  ctx: ExtensionContext,
  firstPrompt?: string,
): string | undefined {
  const entries = ctx.sessionManager.getBranch();
  const summary = entries.findLast(
    (entry) => entry.type === "compaction",
  )?.summary;
  const messages = entries.flatMap((entry) =>
    entry.type === "message" &&
    (entry.message.role === "user" || entry.message.role === "assistant")
      ? [entry.message]
      : [],
  );
  const recent =
    messages
      .slice(-5)
      .map((message) => {
        const text = textOf(message.content);
        const speaker = message.role === "user" ? "User" : "Assistant";
        return text ? `${speaker}: ${text}` : "";
      })
      .filter(Boolean)
      .join("\n\n") || (firstPrompt ? `User: ${firstPrompt}` : "");

  const sections = [
    summary && `Compacted session:\n${summary.slice(0, MAX_SECTION_CHARS)}`,
    recent && `Recent conversation:\n${recent.slice(-MAX_SECTION_CHARS)}`,
  ].filter(Boolean);
  return sections.length > 0 ? sections.join("\n\n") : undefined;
}

function countUserMessages(ctx: ExtensionContext): number {
  return ctx.sessionManager
    .getBranch()
    .filter(
      (entry) => entry.type === "message" && entry.message.role === "user",
    ).length;
}

function textOf(content: unknown): string | undefined {
  const text =
    typeof content === "string"
      ? content
      : Array.isArray(content)
        ? content
            .map((block) =>
              block?.type === "text" && typeof block.text === "string"
                ? block.text
                : "",
            )
            .join(" ")
        : "";
  return text.replace(/\s+/g, " ").trim() || undefined;
}

function sanitizeTitle(value: string | undefined): string | undefined {
  const title = value
    ?.replace(/^['"`“”‘’]+|['"`“”‘’]+$/g, "")
    .replace(/\s+/g, " ")
    .trim();
  if (!title) return undefined;
  return title.length <= MAX_TITLE_CHARS
    ? title
    : `${title.slice(0, MAX_TITLE_CHARS - 1).trim()}…`;
}

function fallbackTitle(prompt: string): string | undefined {
  const words = prompt
    .replace(
      /^(?:Compacted session|Recent conversation|User|Assistant):/gim,
      " ",
    )
    .replace(/```[\s\S]*?```/g, " ")
    .replace(/https?:\/\/\S+/g, " ")
    .replace(/[^\p{L}\p{N}\s_-]/gu, " ")
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 6)
    .join(" ");
  return sanitizeTitle(words);
}
