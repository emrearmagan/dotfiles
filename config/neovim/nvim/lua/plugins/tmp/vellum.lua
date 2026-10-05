return {
	"blackhat-7/vellum.nvim",
	ft = "markdown",
	opts = {},
	config = function(_, opts)
		local vellum = require("vellum")
		vellum.setup(opts)

		local function update(event)
			vim.schedule(function()
				if vim.api.nvim_get_current_buf() ~= event.buf then
					return
				end
				local bo = vim.bo[event.buf]
				if bo.filetype ~= "markdown" then
					return
				end
				if
					bo.buftype ~= ""
					or vim.api.nvim_win_get_config(0).relative ~= ""
					or not bo.modifiable
					or bo.readonly
					or vim.w.codediff_restore ~= nil
					or vim.api.nvim_buf_get_name(event.buf):find("/.codex/editor/", 1, true) -- for some reason its filetype is markdown
				then
					vellum.close()
				elseif event.event ~= "BufEnter" then
					vellum.open()
				end
			end)
		end

		vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter", "BufEnter" }, {
			group = vim.api.nvim_create_augroup("vellum_auto_open", { clear = true }),
			callback = update,
		})
		update({ buf = vim.api.nvim_get_current_buf() })
	end,
}
