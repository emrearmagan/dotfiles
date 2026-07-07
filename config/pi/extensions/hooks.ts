import { spawn } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const AGENT_STATUS_HOOK = join(homedir(), ".config", "scripts", "agent-status-hook");
const MAX_RAW_CHARS = 8000;

export default function (pi: ExtensionAPI) {
	const emit = (eventName: string, options: { state?: string; summary?: string } = {}) => (event?: unknown, ctx?: unknown) => {
		void send(ctx, eventName, event, options);
	};

	pi.on("project_trust", emit("project_trust"));
	pi.on("resources_discover", emit("resources_discover"));

	pi.on("session_start", emit("session_start"));
	pi.on("session_info_changed", emit("session_info_changed"));
	pi.on("session_before_switch", emit("session_before_switch"));
	pi.on("session_before_fork", emit("session_before_fork"));
	pi.on("session_before_compact", emit("session_before_compact"));
	pi.on("session_compact", emit("session_compact"));
	pi.on("session_before_tree", emit("session_before_tree"));
	pi.on("session_tree", emit("session_tree"));
	pi.on("session_shutdown", emit("session_shutdown"));

	pi.on("input", emit("input"));
	pi.on("before_agent_start", emit("before_agent_start"));
	pi.on("agent_start", emit("agent_start"));
	pi.on("agent_end", emit("agent_end"));
	pi.on("turn_start", emit("turn_start"));
	pi.on("turn_end", emit("turn_end"));

	pi.on("message_start", emit("message_start"));
	pi.on("message_end", emit("message_end"));

	pi.on("tool_execution_start", emit("tool_execution_start"));
	pi.on("tool_call", emit("tool_call"));
	pi.on("tool_result", emit("tool_result"));
	pi.on("tool_execution_end", emit("tool_execution_end"));

	pi.on("model_select", emit("model_select"));
	pi.on("thinking_level_select", emit("thinking_level_select"));
	pi.on("user_bash", emit("user_bash"));

	pi.events.on("permissions:ui_prompt", emit("permission", { state: "attention", summary: "permission prompt" }));
	pi.events.on("permissions:decision", emit("permission", { state: "running", summary: "permission decision" }));
}

function send(ctx: unknown, eventName: string, event: unknown, options: { state?: string; summary?: string }): void {
	const args = [
		"--provider",
		"pi",
		"--event",
		eventName,
	];

	const session = sessionID(ctx);
	if (session) args.push("--session", session);
	if (options.state) args.push("--state", options.state);
	if (options.summary) args.push("--summary", options.summary);

	try {
		const child = spawn(AGENT_STATUS_HOOK, args, {
			env: {
				...process.env,
				AGENT_STATUS_ID: process.env.AGENT_STATUS_ID ?? String(process.pid),
			},
			stdio: ["pipe", "ignore", "ignore"],
			detached: true,
		});
		child.on("error", () => {});
		child.stdin?.on("error", () => {});
		child.stdin?.end(truncate(stringify(event ?? {}), MAX_RAW_CHARS));
		child.unref();
	} catch {
		// best-effort; never disrupt pi
	}
}

function sessionID(ctx: unknown): string {
	const maybeContext = ctx as { sessionManager?: { getSessionId?: () => string } } | undefined;
	try {
		return maybeContext?.sessionManager?.getSessionId?.() ?? "";
	} catch {
		return "";
	}
}

function stringify(value: unknown): string {
	const seen = new WeakSet<object>();
	try {
		return JSON.stringify(value, (_key, item) => {
			if (typeof item !== "object" || item === null) return item;
			if (seen.has(item)) return "[Circular]";
			seen.add(item);
			return item;
		}) ?? "";
	} catch {
		return String(value);
	}
}

function truncate(value: string, max: number): string {
	return value.length > max ? `${value.slice(0, max)}…` : value;
}
