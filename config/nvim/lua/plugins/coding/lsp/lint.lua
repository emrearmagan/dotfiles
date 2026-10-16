return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPost", "BufNewFile" },
	dependencies = { "mason-org/mason.nvim" },
	config = function()
		local lint = require("lint")
		lint.linters_by_ft = {
			lua = { "selene" },
			luau = { "selene" },
			swift = { "swiftlint" },
			go = { "golangcilint" },
		}

		-- Keep linting unsaved Swift text; discover each project's config via cwd.
		local swiftlint = lint.linters.swiftlint
		lint.linters.swiftlint = function()
			local linter = swiftlint()
			linter.stdin = true
			linter.args = { "lint", "--use-stdin", "--quiet", "--reporter", "xcode" }
			return linter
		end

		-- Resolve the package from this file, independently of Neovim's launch directory.
		lint.linters.golangcilint = function()
			local linter = require("lint.linters.golangcilint")
			linter.args[#linter.args] = function()
				local file = vim.api.nvim_buf_get_name(0)
				return vim.fs.root(file, "go.mod") and vim.fs.dirname(file) or file
			end
			return linter
		end

		local tools = {
			selene = { command = "selene", roots = { "selene.toml", ".git" } },
			swiftlint = { command = "swiftlint", roots = { ".swiftlint.yml", "Package.swift", ".git" } },
			golangcilint = { command = "golangci-lint", roots = { "go.mod", "go.work", ".git" } },
		}
		vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
			group = vim.api.nvim_create_augroup("user_lint", { clear = true }),
			callback = function(event)
				local file = vim.api.nvim_buf_get_name(event.buf)
				if vim.bo[event.buf].buftype ~= "" or file == "" then
					return
				end
				local linters = lint.linters_by_ft[vim.bo[event.buf].filetype] or {}
				vim.api.nvim_buf_call(event.buf, function()
					for _, name in ipairs(linters) do
						local tool = tools[name]
						if not tool or vim.fn.executable(tool.command) == 1 then
							local cwd = tool and (vim.fs.root(file, tool.roots) or vim.fs.dirname(file))
							lint.try_lint(name, {
								cwd = cwd,
								filter = event.event == "InsertLeave" and "stdin" or nil,
							})
						end
					end
				end)
			end,
		})
	end,
}
