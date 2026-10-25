/**
 * Status Bar Extension
 *
 * Replaces pi's footer with one full-width line: the context tokens, the
 * session cost and a context bar on the left, and the git branch, the model
 * with its thinking level and the status texts other extensions set (such as
 * "yolo" from the permission system) on the right. The context bar turns
 * yellow from 50% and red from 80%.
 *
 * Usage:
 *   Runs automatically.
 */

import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const BAR_WIDTH = 12;

function fmtTokens(n: number): string {
  if (n < 1000) return `${n}`;
  if (n < 1_000_000) return `${(n / 1000).toFixed(1)}k`;
  return `${(n / 1_000_000).toFixed(1)}M`;
}

export default function (pi: ExtensionAPI) {
  let redraw = () => {};
  pi.on("thinking_level_select", async () => redraw());

  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.setFooter((tui, theme, footerData) => {
      redraw = () => tui.requestRender();
      const unsub = footerData.onBranchChange(() => tui.requestRender());

      return {
        dispose: unsub,
        invalidate() {},
        render(width: number): string[] {
          let cost = 0;
          for (const e of ctx.sessionManager.getBranch()) {
            if (e.type === "message" && e.message.role === "assistant") {
              cost += (e.message as AssistantMessage).usage.cost.total;
            }
          }

          const usage = ctx.getContextUsage();
          const used = usage?.tokens ?? 0;
          const total = usage?.contextWindow ?? ctx.model?.contextWindow ?? 0;
          // percent is null when the token count is unknown, e.g. right after compaction
          const pct = Math.min(
            100,
            Math.max(
              0,
              usage?.percent ?? (total > 0 ? (used / total) * 100 : 0),
            ),
          );
          const barColor =
            pct >= 80 ? "error" : pct >= 50 ? "warning" : "muted";
          const filled = Math.round((pct / 100) * BAR_WIDTH);
          const bar =
            theme.fg(barColor, "━".repeat(filled)) +
            theme.fg("dim", "─".repeat(BAR_WIDTH - filled));

          const branch = footerData.getGitBranch();
          // The thinking level only means something for models that can think
          const level = pi.getThinkingLevel();
          const thinking = ctx.model?.reasoning ? ` (${level})` : "";
          const modelColor = ctx.model?.reasoning
            ? theme.getThinkingBorderColor(level)
            : (text: string) => theme.fg("dim", text);
          const statuses = [
            ...footerData.getExtensionStatuses().values(),
          ].filter(Boolean);

          const tokens = theme.fg(
            "dim",
            `${fmtTokens(used)}/${fmtTokens(total)}`,
          );
          const context = `${bar} ${theme.fg(barColor, `${pct.toFixed(0)}%`)}`;
          const model = modelColor(`${ctx.model?.id ?? "no model"}${thinking}`);
          const left = `${tokens}  ${theme.fg("dim", `$${cost.toFixed(2)}`)}  ${context}`;
          const branchAndModel = branch
            ? theme.fg("dim", `⎇ ${branch} - `) + model
            : model;
          const right = [
            branchAndModel,
            ...statuses.map((status) => theme.fg("warning", status)),
          ].join(" ");

          const gap = width - visibleWidth(left) - visibleWidth(right);
          if (gap >= 1) return [left + " ".repeat(gap) + right];
          // Too narrow: keep the model and cut the left side
          if (visibleWidth(right) >= width)
            return [truncateToWidth(right, width)];
          return [
            `${truncateToWidth(left, width - visibleWidth(right) - 1)} ${right}`,
          ];
        },
      };
    });
  });
}
