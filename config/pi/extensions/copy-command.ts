/**
 * Copy Command Extension
 *
 * Adds `/copy-command` and `/cpc` commands that scan recent assistant messages,
 * let you search/pick a shell command, and copy it to the clipboard.
 *
 * Usage:
 *   /copy-command
 *   /cpc
 */

import { spawnSync } from "node:child_process";
import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import { DynamicBorder } from "@earendil-works/pi-coding-agent";
import { Container, Input, Key, matchesKey, SelectList, Text, type SelectItem } from "@earendil-works/pi-tui";

const SHELL_FENCE_RE = /```(?:bash|sh|shell|zsh)?\s*\n([\s\S]*?)```/gi;
const PROMPT_RE = /^\s*(?:[$❯>]\s+)(.+)$/;
const COMMAND_RE = /^\s*(?:(?:[A-Z_]+=\S+\s+)*(?:brew|cd|chmod|cp|curl|docker|find|gh|git|grep|jq|ls|make|mkdir|mv|npm|npx|pnpm|pi|rg|rm|sed|ssh|tmux|yarn)\b|[./~]\S+)/;
const SKIP_RE = /^\s*(?:#|\/\/|$|```|[-*]\s|\w[\w -]*:)$/;

type CommandChoice = {
	label: string;
	command: string;
	source: string;
};

type ContentBlock = {
	type?: string;
	text?: string;
};

type SessionEntry = {
	type: string;
	message?: {
		role?: string;
		content?: unknown;
	};
};

function copyToClipboard(text: string): void {
	if (process.platform === "darwin") {
		const result = spawnSync("pbcopy", [], {
			input: text,
			encoding: "utf8",
			stdio: ["pipe", "ignore", "pipe"],
		});
		if (!result.error && result.status === 0) return;
	}

	process.stdout.write(`\x1b]52;c;${Buffer.from(text, "utf8").toString("base64")}\x07`);
}

function textFromContent(content: unknown): string {
	if (typeof content === "string") return content;
	if (!Array.isArray(content)) return "";

	return content
		.filter((part): part is ContentBlock => !!part && typeof part === "object")
		.filter((part) => part.type === "text" && typeof part.text === "string")
		.map((part) => part.text)
		.join("\n");
}

function commandLabel(command: string): string {
	const firstLine = command.trim().split("\n")[0] ?? command;
	return firstLine.length > 90 ? `${firstLine.slice(0, 87)}…` : firstLine;
}

function extractCommands(text: string, source: string): CommandChoice[] {
	const commands: CommandChoice[] = [];

	for (const match of text.matchAll(SHELL_FENCE_RE)) {
		const command = match[1]?.trim();
		if (command) commands.push({ command, label: commandLabel(command), source });
	}

	for (const line of text.split("\n")) {
		if (line.includes("```")) continue;
		const promptMatch = line.match(PROMPT_RE);
		const command = (promptMatch?.[1] ?? line).trim();
		if (!command || SKIP_RE.test(command) || !COMMAND_RE.test(command)) continue;
		commands.push({ command, label: commandLabel(command), source });
	}

	const seen = new Set<string>();
	return commands.filter((item) => {
		if (seen.has(item.command)) return false;
		seen.add(item.command);
		return true;
	});
}

function getRecentAssistantCommands(ctx: ExtensionCommandContext): CommandChoice[] {
	const entries = ctx.sessionManager.getBranch() as SessionEntry[];
	const choices: CommandChoice[] = [];
	let assistantMessages = 0;

	for (let i = entries.length - 1; i >= 0 && assistantMessages < 20; i--) {
		const entry = entries[i];
		if (entry?.type !== "message" || entry.message?.role !== "assistant") continue;
		assistantMessages++;

		const text = textFromContent(entry.message.content);
		if (!text.trim()) continue;
		choices.push(...extractCommands(text, assistantMessages === 1 ? "last assistant message" : `${assistantMessages} assistant messages ago`));
	}

	return choices;
}

async function pickCommand(choices: CommandChoice[], ctx: ExtensionCommandContext): Promise<CommandChoice | null> {
	if (ctx.mode !== "tui") return choices[0] ?? null;

	const byCommand = new Map(choices.map((choice) => [choice.command, choice]));
	const items: SelectItem[] = choices.map((choice) => ({
		value: choice.command,
		label: choice.label,
		description: choice.source,
	}));

	const selected = await ctx.ui.custom<string | null>((tui, theme, _keybindings, done) => {
		const container = new Container();
		const search = new Input();
		const list = new SelectList(items, Math.min(items.length, 12), {
			selectedPrefix: (text) => theme.fg("accent", text),
			selectedText: (text) => theme.fg("accent", text),
			description: (text) => theme.fg("muted", text),
			scrollInfo: (text) => theme.fg("dim", text),
			noMatch: (text) => theme.fg("warning", text),
		});

		list.onSelect = (item) => done(item.value);
		list.onCancel = () => done(null);
		search.onSubmit = () => {
			const item = list.getSelectedItem();
			if (item) done(item.value);
		};
		search.onEscape = () => done(null);

		container.addChild(new DynamicBorder((text: string) => theme.fg("accent", text)));
		container.addChild(new Text(theme.fg("accent", theme.bold("Copy command")), 1, 0));
		container.addChild(new Text(theme.fg("dim", "Search:"), 1, 0));
		container.addChild(search);
		container.addChild(list);
		container.addChild(new Text(theme.fg("dim", "type to search • ↑↓/ctrl+jk pick • enter copy • esc cancel"), 1, 0));
		container.addChild(new DynamicBorder((text: string) => theme.fg("accent", text)));

		return {
			render: (width: number) => container.render(width),
			invalidate: () => container.invalidate(),
			handleInput: (data: string) => {
				if (matchesKey(data, Key.ctrl("k"))) {
					list.handleInput("\x1b[A");
				} else if (matchesKey(data, Key.ctrl("j"))) {
					list.handleInput("\x1b[B");
				} else if (matchesKey(data, "up") || matchesKey(data, "down") || matchesKey(data, "enter")) {
					list.handleInput(data);
				} else {
					const before = search.getValue();
					search.handleInput(data);
					const after = search.getValue();
					if (after !== before) list.setFilter(after);
				}
				tui.requestRender();
			},
		};
	});

	return selected === null ? null : byCommand.get(selected) ?? null;
}

export default function copyCommandExtension(pi: ExtensionAPI): void {
	const handler = async (_args: string, ctx: ExtensionCommandContext) => {
		const choices = getRecentAssistantCommands(ctx);
		if (choices.length === 0) {
			ctx.ui.notify("No commands found in recent assistant messages.", "warning");
			return;
		}

		const choice = await pickCommand(choices, ctx);
		if (!choice) return;

		copyToClipboard(choice.command);
		ctx.ui.notify(`Copied command: ${choice.label}`, "info");
	};

	pi.registerCommand("copy-command", {
		description: "Pick a recent assistant command and copy it to the clipboard",
		handler,
	});
	pi.registerCommand("cpc", {
		description: "Alias for /copy-command",
		handler,
	});
}
