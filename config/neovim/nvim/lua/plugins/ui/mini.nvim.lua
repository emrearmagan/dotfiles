return {
	{
		-- Smarter text objects (quotes, brackets, tags, etc.)
		-- Lets you use things like:
		--   ciq → change inside *any* quotes (' " `)
		--   cib → change inside brackets/parentheses
		--   cit → change inside HTML/XML tags
		-- Works automatically with which-key and operators (c/d/y)
		"echasnovski/mini.ai",
		version = "*",
		event = "VeryLazy",
		config = function()
			require("mini.ai").setup()
		end,
	},
	{
		"nvim-mini/mini.animate",
		version = "*",
		event = "VeryLazy",
	},
	{
		"nvim-mini/mini.files",
		version = "*",
		opts = {
			options = {
				use_as_default_explorer = true,
			},
			mappings = {
				close = "q",
				go_in = "l",
				go_in_plus = "L",
				go_out = "h",
				go_out_plus = "H",
				mark_goto = "'",
				mark_set = "m",
				reset = "<BS>",
				reveal_cwd = "@",
				show_help = "g?",
				synchronize = "=",
				trim_left = "<",
				trim_right = ">",
			},
			windows = {
				-- Maximum number of windows to show side by side
				max_number = math.huge,
				-- Whether to show preview of file/directory under cursor
				preview = true,
				-- Width of focused window
				width_focus = 50,
				-- Width of non-focused window
				width_nofocus = 15,
				-- Width of preview window
				width_preview = 100,
			},
		},
		config = function(_, opts)
			local mini_files = require("mini.files")
			mini_files.setup(opts)

			vim.api.nvim_create_autocmd("User", {
				pattern = "MiniFilesBufferCreate",
				callback = function(args)
					local buf_id = args.data.buf_id
					vim.keymap.set("n", "<esc>", function()
						mini_files.close()
					end, { buffer = buf_id, desc = "Close mini.files" })

					vim.keymap.set("n", "l", function()
						mini_files.go_in({ close_on_file = true })
					end, { buffer = buf_id, desc = "Open and close mini.files" })

					vim.keymap.set("n", "<CR>", function()
						mini_files.go_in({ close_on_file = true })
					end, { buffer = buf_id, desc = "Open and close mini.files" })
				end,
			})

			local nsMiniFiles = vim.api.nvim_create_namespace("mini_files_git")
			local autocmd = vim.api.nvim_create_autocmd
			local _, MiniFiles = pcall(require, "mini.files")
			-- Reference: https://gist.github.com/bassamsdata/eec0a3065152226581f8d4244cce9051#file-notes-md

			local gitStatusCache = {}
			local cacheTimeout = 2000
			local uv = vim.uv or vim.loop

			local function isSymlink(path)
				local stat = uv.fs_lstat(path)
				return stat and stat.type == "link"
			end

			local function mapSymbols(status, is_symlink)
				local statusMap = {
					[" M"] = { symbol = "•", hlGroup = "MiniDiffSignChange" },
					["M "] = { symbol = "✹", hlGroup = "MiniDiffSignChange" },
					["MM"] = { symbol = "≠", hlGroup = "MiniDiffSignChange" },
					["A "] = { symbol = "+", hlGroup = "MiniDiffSignAdd" },
					["AA"] = { symbol = "≈", hlGroup = "MiniDiffSignAdd" },
					["D "] = { symbol = "-", hlGroup = "MiniDiffSignDelete" },
					["AM"] = { symbol = "⊕", hlGroup = "MiniDiffSignChange" },
					["AD"] = { symbol = "-•", hlGroup = "MiniDiffSignChange" },
					["R "] = { symbol = "→", hlGroup = "MiniDiffSignChange" },
					["U "] = { symbol = "‖", hlGroup = "MiniDiffSignChange" },
					["UU"] = { symbol = "⇄", hlGroup = "MiniDiffSignAdd" },
					["UA"] = { symbol = "⊕", hlGroup = "MiniDiffSignAdd" },
					["??"] = { symbol = "?", hlGroup = "MiniDiffSignDelete" },
					["!!"] = { symbol = "!", hlGroup = "MiniDiffSignChange" },
				}

				local result = statusMap[status] or { symbol = "?", hlGroup = "NonText" }
				local gitSymbol = result.symbol
				local gitHlGroup = result.hlGroup

				local symlinkSymbol = is_symlink and "↩" or ""

				local combinedSymbol = (symlinkSymbol .. gitSymbol):gsub("^%s+", ""):gsub("%s+$", "")
				local combinedHlGroup = is_symlink and "MiniDiffSignDelete" or gitHlGroup

				return combinedSymbol, combinedHlGroup
			end

			local function fetchGitStatus(cwd, callback)
				local clean_cwd = cwd:gsub("^minifiles://%d+/", "")
				local function on_exit(content)
					if content.code == 0 then
						callback(content.stdout)
					end
				end

				vim.system({ "git", "status", "--ignored", "--porcelain" }, { text = true, cwd = clean_cwd }, on_exit)
			end

			local function updateMiniWithGit(buf_id, gitStatusMap)
				vim.schedule(function()
					local nlines = vim.api.nvim_buf_line_count(buf_id)
					local cwd = vim.fs.root(buf_id, ".git")
					local escapedcwd = cwd and vim.pesc(cwd)
					escapedcwd = vim.fs.normalize(escapedcwd)

					for i = 1, nlines do
						local entry = MiniFiles.get_fs_entry(buf_id, i)
						if not entry then
							break
						end

						local relativePath = entry.path:gsub("^" .. escapedcwd .. "/", "")
						local status = gitStatusMap[relativePath]

						if status then
							local symbol, hlGroup = mapSymbols(status, isSymlink(entry.path))
							vim.api.nvim_buf_set_extmark(buf_id, nsMiniFiles, i - 1, 0, {
								sign_text = symbol,
								sign_hl_group = hlGroup,
								priority = 2,
							})

							local line = vim.api.nvim_buf_get_lines(buf_id, i - 1, i, false)[1]
							local nameStartCol = line:find(vim.pesc(entry.name)) or 0

							if nameStartCol > 0 then
								vim.api.nvim_buf_set_extmark(buf_id, nsMiniFiles, i - 1, nameStartCol - 1, {
									end_col = nameStartCol + #entry.name - 1,
									hl_group = hlGroup,
								})
							end
						end
					end
				end)
			end

			local function parseGitStatus(content)
				local gitStatusMap = {}
				for line in content:gmatch("[^\r\n]+") do
					local status, filePath = string.match(line, "^(..)%s+(.*)")
					local parts = {}
					for part in filePath:gmatch("[^/]+") do
						table.insert(parts, part)
					end

					local currentKey = ""
					for i, part in ipairs(parts) do
						if i > 1 then
							currentKey = currentKey .. "/" .. part
						else
							currentKey = part
						end

						if i == #parts then
							gitStatusMap[currentKey] = status
						else
							if not gitStatusMap[currentKey] then
								gitStatusMap[currentKey] = status
							end
						end
					end
				end
				return gitStatusMap
			end

			local function updateGitStatus(buf_id)
				if not vim.fs.root(buf_id, ".git") then
					return
				end
				local cwd = vim.fs.root(buf_id, ".git")
				local currentTime = os.time()

				if gitStatusCache[cwd] and currentTime - gitStatusCache[cwd].time < cacheTimeout then
					updateMiniWithGit(buf_id, gitStatusCache[cwd].statusMap)
				else
					fetchGitStatus(cwd, function(content)
						local gitStatusMap = parseGitStatus(content)
						gitStatusCache[cwd] = {
							time = currentTime,
							statusMap = gitStatusMap,
						}
						updateMiniWithGit(buf_id, gitStatusMap)
					end)
				end
			end

			local function clearCache()
				gitStatusCache = {}
			end

			local function augroup(name)
				return vim.api.nvim_create_augroup("MiniFiles_" .. name, { clear = true })
			end

			autocmd("User", {
				group = augroup("start"),
				pattern = "MiniFilesExplorerOpen",
				callback = function()
					local bufnr = vim.api.nvim_get_current_buf()
					updateGitStatus(bufnr)
				end,
			})

			autocmd("User", {
				group = augroup("close"),
				pattern = "MiniFilesExplorerClose",
				callback = function()
					clearCache()
				end,
			})

			autocmd("User", {
				group = augroup("update"),
				pattern = "MiniFilesBufferUpdate",
				callback = function(args)
					local bufnr = args.data.buf_id
					local cwd = vim.fs.root(bufnr, ".git")
					if gitStatusCache[cwd] then
						updateMiniWithGit(bufnr, gitStatusCache[cwd].statusMap)
					end
				end,
			})
		end,
	},
	{
		"nvim-mini/mini.tabline",
		version = "*",
		event = "VeryLazy",
		opts = {},
		config = function(_, opts)
			require("mini.tabline").setup(opts)

			-- Mini has no public ordering API, so sort its generated tabs by first-listed order.
			local function preserve_buffer_order()
				local helpers
				for index = 1, math.huge do
					local name, value = debug.getupvalue(MiniTabline.make_tabline_string, index)
					if not name then
						break
					end
					if name == "H" then
						helpers = value
						break
					end
				end

				if not helpers or type(helpers.list_tabs) ~= "function" or type(helpers.tabs) ~= "table" then
					vim.notify("Unable to customize mini.tabline buffer order", vim.log.levels.WARN)
					return
				end
				if helpers.user_preserves_buffer_order then
					return
				end

				local next_order = 0
				local function get_order(buf_id)
					local order = vim.b[buf_id].user_minitabline_order
					if type(order) ~= "number" then
						next_order = next_order + 1
						order = next_order
						vim.b[buf_id].user_minitabline_order = order
					else
						next_order = math.max(next_order, order)
					end
					return order
				end

				for _, buf_id in ipairs(vim.api.nvim_list_bufs()) do
					if vim.bo[buf_id].buflisted then
						get_order(buf_id)
					end
				end

				local list_tabs = helpers.list_tabs
				helpers.list_tabs = function()
					list_tabs()
					for _, tab in ipairs(helpers.tabs) do
						get_order(tab.buf_id)
					end
					table.sort(helpers.tabs, function(a, b)
						return get_order(a.buf_id) < get_order(b.buf_id)
					end)
				end
				helpers.user_preserves_buffer_order = true
			end

			preserve_buffer_order()

			local function set_highlights()
				local colors = require("catppuccin.palettes").get_palette()
				local highlights = {
					MiniTablineCurrent = { fg = colors.blue, bg = colors.surface0 },
					MiniTablineVisible = { fg = colors.subtext0, bg = "NONE" },
					MiniTablineHidden = { fg = colors.overlay1, bg = "NONE" },
					MiniTablineModifiedCurrent = { fg = colors.peach, bg = colors.surface0 },
					MiniTablineModifiedVisible = { fg = colors.peach, bg = "NONE" },
					MiniTablineModifiedHidden = { fg = colors.peach, bg = "NONE" },
					MiniTablineFill = { bg = "NONE" },
					MiniTablineTabpagesection = { fg = colors.overlay1, bg = "NONE" },
				}

				for group, highlight in pairs(highlights) do
					vim.api.nvim_set_hl(0, group, highlight)
				end
			end

			local group = vim.api.nvim_create_augroup("mini_tabline", { clear = true })
			set_highlights()
			vim.api.nvim_create_autocmd("ColorScheme", {
				group = group,
				callback = set_highlights,
			})

			local function update_visibility()
				vim.o.showtabline = #vim.fn.getbufinfo({ buflisted = 1 }) > 1 and 2 or 0
			end

			update_visibility()
			vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufEnter" }, {
				group = group,
				callback = function()
					vim.schedule(update_visibility)
				end,
			})
		end,
	},
}
