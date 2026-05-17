return {
	"kevinhwang91/nvim-ufo",
	dependencies = {
		"kevinhwang91/promise-async",
	},
	event = "BufReadPost",
	init = function()
		-- Fold settings (must be set before ufo loads)
		vim.o.foldcolumn = "1"
		vim.o.foldlevel = 99
		vim.o.foldlevelstart = 99
		vim.o.foldenable = true
	end,
	keys = {
		{
			"zR",
			function()
				require("ufo").openAllFolds()
			end,
			desc = "Open all folds",
		},
		{
			"zA",
			function()
				require("ufo").closeAllFolds()
			end,
			desc = "Close all folds",
		},
	},
	config = function()
		local function fold_virt_text(virtText, _, endLnum, _, _, ctx)
			table.insert(virtText, { " ... ", "Comment" })
			for _, chunk in ipairs(ctx.get_fold_virt_text(endLnum)) do
				if chunk[1]:match("%S") then
					table.insert(virtText, chunk)
				end
			end
			return virtText
		end

		require("ufo").setup({
			provider_selector = function()
				return { "treesitter", "indent" }
			end,
			enable_get_fold_virt_text = true,
			fold_virt_text_handler = fold_virt_text,
		})

		-- remove some highlights for folding
		local function clear_hl()
			vim.api.nvim_set_hl(0, "Folded", { bg = "NONE", link = "Comment" })
			vim.api.nvim_set_hl(0, "UfoFoldedBg", { bg = "NONE" })
			vim.api.nvim_set_hl(0, "UfoFoldedFg", { link = "Comment" })
			vim.api.nvim_set_hl(0, "UfoFoldedEllipsis", { bg = "NONE", link = "Comment" })
		end
		clear_hl()
		vim.api.nvim_create_autocmd("ColorScheme", { callback = clear_hl })
	end,
}
