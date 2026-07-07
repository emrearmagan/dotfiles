/**
 * Enter Follow-up Extension
 *
 * Cursor-style local queue for prompts submitted while Pi is working:
 * - typing text + Enter while streaming queues it locally (no built-in follow-ups box)
 * - queued prompts render in a compact border above the editor, without a title
 * - empty-editor Enter sends the next queued prompt immediately as steering
 * - ↑ edits the next queued prompt, Esc cancels the local queue
 */

import {
	CustomEditor,
	type ExtensionAPI,
	type ExtensionContext,
	type KeybindingsManager,
	type Theme,
} from "@earendil-works/pi-coding-agent";
import {
	matchesKey,
	truncateToWidth,
	visibleWidth,
	wrapTextWithAnsi,
	type Component,
	type EditorTheme,
	type TUI,
} from "@earendil-works/pi-tui";

type ImagePart = { type: string; [key: string]: unknown };

type QueuedPrompt = {
	text: string;
	images?: readonly ImagePart[];
};

const WIDGET_KEY = "enter-followup.queue";

function contentWithImages(prompt: QueuedPrompt): string | Array<{ type: "text"; text: string } | ImagePart> {
	if (!prompt.images || prompt.images.length === 0) return prompt.text;
	return [{ type: "text", text: prompt.text }, ...prompt.images];
}

function plainPreview(text: string): string {
	return text.replace(/\s+/g, " ").trim();
}

function fit(line: string, width: number): string {
	return truncateToWidth(line, Math.max(0, width), "");
}

function borderedLine(text: string, width: number, theme: Theme): string {
	if (width <= 0) return "";
	if (width === 1) return theme.fg("borderAccent", "│");
	const innerWidth = Math.max(0, width - 2);
	const content = fit(text, innerWidth);
	const pad = Math.max(0, innerWidth - visibleWidth(content));
	return `${theme.fg("borderAccent", "│")}${content}${" ".repeat(pad)}${theme.fg("borderAccent", "│")}`;
}

class QueuedPromptWidget implements Component {
	constructor(
		private readonly getQueue: () => readonly QueuedPrompt[],
		private readonly theme: Theme,
	) {}

	render(width: number): string[] {
		const queue = this.getQueue();
		if (queue.length === 0) return [];

		const borderWidth = Math.max(1, width);
		const innerWidth = Math.max(0, borderWidth - 2);
		const top = this.theme.fg("borderAccent", borderWidth <= 1 ? "─" : `╭${"─".repeat(Math.max(0, borderWidth - 2))}╮`);
		const bottom = this.theme.fg("borderAccent", borderWidth <= 1 ? "─" : `╰${"─".repeat(Math.max(0, borderWidth - 2))}╯`);

		const lines: string[] = [top];
		const visiblePrompts = queue.slice(0, 3);
		for (const [index, prompt] of visiblePrompts.entries()) {
			const marker = queue.length === 1 ? "○ " : `${index + 1}. `;
			const suffix = prompt.images?.length ? ` ${this.theme.fg("muted", `[${prompt.images.length} image${prompt.images.length === 1 ? "" : "s"}]`)}` : "";
			const text = `${this.theme.fg("muted", marker)}${this.theme.fg("text", plainPreview(prompt.text))}${suffix}`;
			const wrapped = wrapTextWithAnsi(text, Math.max(1, innerWidth - 2));
			for (const [lineIndex, wrappedLine] of wrapped.entries()) {
				const indent = lineIndex === 0 ? " " : "   ";
				lines.push(borderedLine(`${indent}${wrappedLine}`, borderWidth, this.theme));
			}
		}

		if (queue.length > visiblePrompts.length) {
			lines.push(borderedLine(this.theme.fg("muted", ` +${queue.length - visiblePrompts.length} more queued`), borderWidth, this.theme));
		}

		lines.push(borderedLine(this.theme.fg("dim", " enter send now · ↑ edit · esc cancel"), borderWidth, this.theme));
		lines.push(bottom);
		return lines;
	}

	invalidate(): void {}
}

class QueueingEditor extends CustomEditor {
	constructor(
		tui: TUI,
		theme: EditorTheme,
		keybindings: KeybindingsManager,
		private readonly callbacks: {
			hasQueue: () => boolean;
			sendNow: () => void;
			editNext: (editor: QueueingEditor) => void;
			cancel: () => void;
		},
	) {
		super(tui, theme, keybindings);
	}

	handleInput(data: string): void {
		const editorIsEmpty = this.getText().trim().length === 0;

		if (this.callbacks.hasQueue() && editorIsEmpty) {
			if (matchesKey(data, "enter")) {
				this.callbacks.sendNow();
				return;
			}
			if (matchesKey(data, "up")) {
				this.callbacks.editNext(this);
				return;
			}
			if (matchesKey(data, "escape")) {
				this.callbacks.cancel();
				return;
			}
		}

		super.handleInput(data);
	}
}

export default function enterFollowupExtension(pi: ExtensionAPI): void {
	let ctx: ExtensionContext | undefined;
	let queue: QueuedPrompt[] = [];
	let editingQueuedPrompt = false;

	const refreshWidget = () => {
		if (!ctx) return;
		if (queue.length === 0) {
			ctx.ui.setWidget(WIDGET_KEY, undefined);
			return;
		}

		ctx.ui.setWidget(
			WIDGET_KEY,
			(_tui, theme) => new QueuedPromptWidget(() => queue, theme),
			{ placement: "aboveEditor" },
		);
	};

	const enqueue = (prompt: QueuedPrompt) => {
		queue.push(prompt);
		editingQueuedPrompt = false;
		refreshWidget();
	};

	const sendPrompt = (prompt: QueuedPrompt, deliverAs: "steer" | "followUp" = "steer") => {
		pi.sendUserMessage(contentWithImages(prompt), { deliverAs });
	};

	const sendNow = () => {
		const prompt = queue.shift();
		if (!prompt) return;
		editingQueuedPrompt = false;
		refreshWidget();
		sendPrompt(prompt, "steer");
	};

	const sendNextAfterIdle = () => {
		const prompt = queue.shift();
		if (!prompt) return;
		editingQueuedPrompt = false;
		refreshWidget();
		// Defer until Pi has fully left the current agent_end dispatch.
		setTimeout(() => sendPrompt(prompt, "steer"), 0);
	};

	const cancelQueue = () => {
		if (queue.length === 0) return;
		const count = queue.length;
		queue = [];
		editingQueuedPrompt = false;
		refreshWidget();
		ctx?.ui.notify(`Cancelled ${count} queued prompt${count === 1 ? "" : "s"}`, "info");
	};

	const requeueEditedPrompt = (prompt: QueuedPrompt) => {
		// Preserve its position as the next queued prompt after editing.
		queue.unshift(prompt);
		editingQueuedPrompt = false;
		refreshWidget();
	};

	const editNext = (editor: QueueingEditor) => {
		const prompt = queue.shift();
		if (!prompt) return;
		editingQueuedPrompt = true;
		refreshWidget();
		editor.setText(prompt.text);
		if (prompt.images?.length) {
			ctx?.ui.notify("Editing restored text only; attached images were removed.", "warning");
		}
	};

	pi.on("session_start", (_event, eventCtx) => {
		ctx = eventCtx;
		const previous = eventCtx.ui.getEditorComponent();
		if (previous) {
			eventCtx.ui.notify("enter-followup replaced an existing custom editor", "warning");
		}
		eventCtx.ui.setEditorComponent((tui, theme, keybindings) =>
			new QueueingEditor(tui, theme, keybindings, {
				hasQueue: () => queue.length > 0,
				sendNow,
				editNext,
				cancel: cancelQueue,
			}),
		);
		refreshWidget();
	});

	pi.on("session_shutdown", () => {
		queue = [];
		ctx = undefined;
	});

	pi.on("agent_end", () => {
		if (!editingQueuedPrompt && queue.length > 0) sendNextAfterIdle();
	});

	pi.on("input", (event) => {
		if (event.source !== "interactive") {
			return { action: "continue" };
		}

		const text = event.text.trim();
		if (!text) return { action: "continue" };

		// Let Pi execute/expand slash commands normally.
		if (text.startsWith("/")) return { action: "continue" };

		const prompt: QueuedPrompt = {
			text: event.text,
			images: event.images as readonly ImagePart[] | undefined,
		};

		if (editingQueuedPrompt) {
			requeueEditedPrompt(prompt);
			return { action: "handled" };
		}

		if (event.streamingBehavior !== "steer") {
			return { action: "continue" };
		}

		enqueue(prompt);
		return { action: "handled" };
	});
}
