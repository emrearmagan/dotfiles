import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function customCommands(pi: ExtensionAPI) {
	pi.registerCommand("find", {
		description: "Find information in past sessions without leaving the current session",
		handler: async (args, ctx) => {
			if (!ctx.isIdle()) {
				ctx.ui.notify("Wait for the current response to finish before using /find", "warning");
				return;
			}

			let query = args.trim();
			if (!query) {
				if (!ctx.hasUI) {
					ctx.ui.notify("Usage: /find <query>", "warning");
					return;
				}
				query = (await ctx.ui.input("Find in past sessions", "what are you looking for?"))?.trim() ?? "";
				if (!query) return;
			}

			const request = [
				"Search my previous Pi sessions for the following request:",
				query,
				"Use session_search for retrieval. Use session_read on up to three strong matches only when their search summaries are insufficient. Answer in this conversation without switching sessions. Mention the relevant session title, project, and date when available. If no relevant history exists, say so.",
			].join("\n\n");
			pi.sendUserMessage(request);
		},
	});
}
