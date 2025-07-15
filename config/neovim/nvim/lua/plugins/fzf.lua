return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" }, -- optional, for file icons
  config = function()
    require("fzf-lua").setup({
      winopts = {
        height = 0.85,   -- Window height (percentage)
        width = 0.80,    -- Window width (percentage)
        preview = {
          vertical = "down:45%", -- Split preview vertically
          horizontal = "right:60%",
        },
      },
      files = {
        prompt = "Files❯ ",
        cmd = "find . -type f", -- Use `find` for better file handling
        previewer = "bat", -- Use `bat` as a previewer
      },
      git = {
        prompt = "GitFiles❯ ",
        cmd = "git ls-files --exclude-standard --cached --others",
        previewer = "git diff", -- Git diff preview
      },
      grep = {
        prompt = "Grep❯ ",
        input_prompt = "Grep For❯ ",
       --- cmd = "grep -rnIH --exclude=dir{.git, node_module} .",
	silent = true,
      },
    })
  end,
}

