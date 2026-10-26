# pi extensions

My own extensions for [pi](https://pi.dev).

- **status-bar.ts**: a one-line footer with the context tokens, session cost and a context bar on the left, and the git branch, model with its thinking level and statuses like `yolo` on the right.
- **background.ts**: lets pi run long commands like builds, test suites and dev servers in the background and wakes it when they finish. Regular bash commands time out after 2 minutes.
- **enter-followup.ts**: queues prompts you send while pi is working and shows them above the editor.
- **auto-session-name.ts**: names sessions from the conversation, so they are easy to find in `/resume`.
- **copy-command.ts**: lets you pick a shell command from recent replies and copy it to the clipboard.
- **clipboard.ts**: lets pi copy text to your clipboard, also over SSH.
- **atlas-notes.ts**: lets pi list and add private Atlas review notes on pull request diffs.
- **hooks.ts**: sends pi's events to `agent-status-hook`, which shows the agent status in sketchybar.
- **ollama-provider.ts**: adds your remote Ollama server as a provider when `OLLAMA_REMOTE_HOST` is set.
