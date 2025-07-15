return {
  "nvim-treesitter/nvim-treesitter",

  -- Load Treesitter after reading or creating a buffer (lazy-load)
  event = { "BufReadPost", "BufNewFile" },

  -- Automatically run :TSUpdate after plugin install/update
  build = ":TSUpdate",

  -- Treesitter setup options
  opts = {
    -- Install only these language parsers
    ensure_installed = {
      "go",         -- Go
      "php",        -- PHP
      "swift",      -- Swift - Custom below, since its not supported
      "typescript", -- TypeScript
      "tsx",        -- Angular/React-style TSX
      "bash",       -- Shell scripting
      "yaml",       -- YAML files
      "json",       -- JSON files
      "lua",        -- Lua (for Neovim config)
      "vim",        -- Vimscript (for Neovim config)
    },

    -- Don’t install parsers synchronously (use async)
    sync_install = false,

    -- Automatically install missing parsers when opening a buffer
    auto_install = true,

    highlight = {
      -- Enable Treesitter-based syntax highlighting
      enable = true,

      -- Don’t run traditional `:syntax` highlighting alongside Treesitter
      additional_vim_regex_highlighting = false,
    },
  },

  -- Setup Treesitter using the opts defined above
  config = function(_, opts)
    local parser_config = require("nvim-treesitter.parsers").get_parser_configs()

    parser_config.swift = {
      install_info = {
        url = "https://github.com/tree-sitter/tree-sitter-swift",
        files = { "src/parser.c", "src/scanner.c" },
        branch = "main",
      },
      filetype = "swift",
    }

    require("nvim-treesitter.configs").setup(opts)
    
    -- Ensure Swift gets installed when custom defined
    vim.cmd("TSInstall! swift")
  end,
}