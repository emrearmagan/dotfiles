/**
 * Reports pi's state to the sketchybar `agent` item via agent-status.sh.
 * Only active inside tmux (status is keyed per tmux window).
 *   agent_start/turn_start/tool_execution_start -> working
 *   agent_end -> idle,  session_shutdown -> close
 *   permissions:ui_prompt -> attention,  permissions:decision -> working
 * (permission channels are observed only; the pi-permission-system owns them.)
 */

import { spawn } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const DISPATCHER = join(homedir(), ".config", "sketchybar", "helpers", "agent-status.sh");

function report(state: "working" | "idle" | "attention" | "close"): void {
	try {
		const child = spawn(DISPATCHER, [state, "pi"], { env: process.env, stdio: "ignore", detached: true });
		child.on("error", () => {});
		child.unref();
	} catch {
		// best-effort; never disrupt pi
	}
}

export default function (pi: ExtensionAPI) {
	if (!process.env.TMUX) return;
	const working = async () => report("working");
	pi.on("agent_start", working);
	pi.on("turn_start", working);
	pi.on("tool_execution_start", working);
	pi.on("agent_end", async () => report("idle"));
	pi.on("session_shutdown", async () => report("close"));
	// Emitted by the @gotgenes/pi-permission-system extension (observed only).
	pi.events.on("permissions:ui_prompt", () => report("attention"));
	pi.events.on("permissions:decision", () => report("working"));
}
