import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { SessionManager } from "@earendil-works/pi-coding-agent";
import { FinderComponent, clamp, type FinderEntry } from "./finder.js";
import { parseSessionDetail, type Outcome, type SessionDetail } from "./parse.js";
import {
	DEFAULT_CONFIG,
	ago,
	extractSnippet,
	projName,
	rankMatches,
	type RankedMatch,
	type RankMode,
	type SearchConfig,
	type SessionInfoLike,
} from "./search.js";

const MAX_RESULTS = 200;
const PREVIEW_SNIPPET_CHARS = 4000;

interface SearchExtensionConfig {
	richPreview: boolean;
	rankMode: RankMode;
}

function parseBoolEnv(value: string | undefined, fallback: boolean): boolean {
	const normalized = (value ?? "").trim().toLowerCase();
	if (!normalized) return fallback;
	return !["0", "false", "no", "off"].includes(normalized);
}

function parseRankMode(value: string | undefined): RankMode {
	const normalized = (value ?? "").trim().toLowerCase();
	return normalized === "rrf" || normalized === "bm25" ? normalized : "heuristic";
}

function resolveConfig(): SearchExtensionConfig {
	return {
		richPreview: parseBoolEnv(process.env.PI_SEARCH_RICH_PREVIEW, true),
		rankMode: parseRankMode(process.env.PI_SEARCH_RANK_MODE),
	};
}

function loadDetailDeferred(path: string): Promise<SessionDetail | null> {
	return new Promise((resolve) =>
		setImmediate(() => {
			try {
				resolve(parseSessionDetail(path));
			} catch {
				resolve(null);
			}
		}),
	);
}

function day(date: Date): string {
	return date.toISOString().slice(0, 10);
}

function buildEntries(matches: RankedMatch[]): FinderEntry[] {
	const previewConfig = { ...DEFAULT_CONFIG, snippetChars: PREVIEW_SNIPPET_CHARS };
	return matches.map((match) => {
		const title =
			match.info.name?.trim() ||
			match.info.firstMessage.slice(0, 80).trim() ||
			"(untitled session)";
		const project = projName(match.info.cwd);
		return {
			path: match.info.path,
			header: `${title}  ·  ${project}  ·  ${ago(match.info.modified)}  ·  ${match.info.messageCount} msg`,
			title,
			detail: `${match.info.cwd || "(unknown project)"}  ·  modified ${day(match.info.modified)}  ·  ${match.info.messageCount} messages`,
			snippet: extractSnippet(match.info.allMessagesText, match.terms, previewConfig),
			terms: match.terms,
			fullText: match.info.allMessagesText,
		};
	});
}

function outcomeLabel(outcome: Outcome): string {
	if (outcome === "landed") return "landed (assistant closed it out)";
	if (outcome === "abandoned") return "abandoned (last action errored)";
	return "open (no closing turn)";
}

function buildRecapCard(detail: SessionDetail, query: string, sessionName: string): string[] {
	const recap = detail.recap;
	const lines = [
		`Previously on "${sessionName}":`,
		`  What you were doing: ${recap.intent}`,
		`  Last action: ${recap.lastAction}`,
	];
	if (recap.nextStep) lines.push(`  Next step: ${recap.nextStep}`);
	lines.push(`  Outcome: ${outcomeLabel(recap.outcome)}`);

	if (detail.locator) {
		lines.push(`  ── match for "${query}" (navigate manually) ──`);
		lines.push(`  message #${detail.locator.index} of ${detail.locator.total}:`);
		lines.push(`  ${detail.locator.text}`);
	} else if (query) {
		lines.push("  (matched session name/project, not the conversation)");
	}
	return lines;
}

export default function sessionSearchExtension(pi: ExtensionAPI) {
	pi.registerCommand("search", {
		description: "Search all sessions by keyword and jump to a match",
		handler: async (args, ctx) => {
			if (!ctx.hasUI) {
				ctx.ui.notify("/search needs interactive mode", "info");
				return;
			}

			let query = args.trim();
			if (!query) {
				query = (await ctx.ui.input("Search sessions", "search keywords…"))?.trim() ?? "";
				if (!query) return;
			}

			ctx.ui.setStatus("session-search", "Scanning all sessions…");
			let sessions: SessionInfoLike[];
			try {
				sessions = await SessionManager.listAll((loaded, total) => {
					if (total) {
						ctx.ui.setStatus("session-search", `Scanning all sessions… ${loaded}/${total}`);
					}
				});
			} catch (error) {
				ctx.ui.setStatus("session-search", undefined);
				ctx.ui.notify(`Failed to list sessions: ${(error as Error).message}`, "error");
				return;
			}
			ctx.ui.setStatus("session-search", undefined);

			const config = resolveConfig();
			const searchConfig: SearchConfig = { ...DEFAULT_CONFIG, rankMode: config.rankMode };
			const matches = rankMatches(sessions, query, searchConfig);
			if (matches.length === 0) {
				ctx.ui.notify(`No sessions matched "${query}"`, "info");
				return;
			}

			const cappedMatches = matches.slice(0, MAX_RESULTS);
			const entries = buildEntries(cappedMatches);
			const title = `Search sessions · ${matches.length} match${matches.length === 1 ? "" : "es"}`;
			let targetPath: string | null = null;

			if (ctx.mode === "tui") {
				targetPath = await ctx.ui.custom<string | null>(
					(tui, theme, _keybindings, done) => {
						const rows = (tui as { terminal?: { rows?: number } }).terminal?.rows ?? 24;
						const targetHeight = clamp(Math.floor(rows * 0.82), 14, Math.max(14, rows - 2));
						const finder = new FinderComponent({
							title,
							entries,
							theme,
							targetHeight,
							loadDetail: config.richPreview ? loadDetailDeferred : undefined,
						});
						finder.onSelect = (path) => done(path);
						finder.onCancel = () => done(null);
						finder.requestRender = () => tui.requestRender();
						return finder;
					},
					{ overlay: true, overlayOptions: { width: "90%", maxHeight: "85%", anchor: "center" } },
				);
			} else {
				const labelToPath = new Map<string, string>();
				const options = entries.map((entry) => {
					let label = entry.snippet ? `${entry.header}  —  ${entry.snippet}` : entry.header;
					if (labelToPath.has(label)) {
						let suffix = 2;
						while (labelToPath.has(`${label} (#${suffix})`)) suffix++;
						label = `${label} (#${suffix})`;
					}
					labelToPath.set(label, entry.path);
					return label;
				});
				const hiddenCount = matches.length - cappedMatches.length;
				const suffix = hiddenCount > 0 ? ` · ${hiddenCount} more` : "";
				const choice = await ctx.ui.select(`${title}${suffix}`, options);
				targetPath = choice ? (labelToPath.get(choice) ?? null) : null;
			}

			if (!targetPath) return;

			const picked = entries.find((entry) => entry.path === targetPath);
			const pickedMatch = cappedMatches.find((match) => match.info.path === targetPath) ?? null;
			const pickedName = picked?.title ?? "session";
			const pickedProject = projName(pickedMatch?.info.cwd ?? "");
			const terms = pickedMatch?.terms ?? [];

			const result = await ctx.switchSession(targetPath, {
				withSession: async (replacementContext) => {
					replacementContext.ui.notify(`Resumed "${pickedName}" in ${pickedProject}`, "info");
					try {
						const detail = parseSessionDetail(targetPath, terms, DEFAULT_CONFIG);
						if (!detail) return;

						replacementContext.ui.setWidget(
							"session-search-recap",
							buildRecapCard(detail, query, pickedName),
							{ placement: "aboveEditor" },
						);
						let unsubscribe: (() => void) | undefined;
						unsubscribe = replacementContext.ui.onTerminalInput((): undefined => {
							try {
								replacementContext.ui.setWidget("session-search-recap", undefined);
							} catch {
								// The widget may already be gone after a UI refresh.
							}
							unsubscribe?.();
							return undefined;
						});
					} catch {
						// Session switching should not fail when the optional recap cannot be rendered.
					}
				},
			});

			if (result.cancelled) ctx.ui.notify("Switch cancelled", "info");
		},
	});
}
