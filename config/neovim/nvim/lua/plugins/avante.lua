-- avante.nvim for AI-powered code chat
return {
  "yetone/avante.nvim",
  -- build function didnt work somehow. Had to run this manually:
  -- cd ~/.local/share/nvim/lazy/avante.nvim & make
  build = function()
    if vim.fn.has("win32") == 1 then
      return "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
    else
      return "make"
    end
  end,
  event = "VeryLazy",
  version = false,

  opts = {
    provider = "openai",
    file_selector = "fzf",
    system_message = "You always respond in English unless explicitly asked",
    providers = {
      openai = {
        -- API key is read from the environment: AVANTE_OPENAI_API_KEY
        model = "gpt-4o",
        endpoint = "https://api.openai.com/v1",
        timeout = 30000,
        extra_request_body = {
          temperature = 0.7,
          max_tokens = 2048,
        },
      },
    },
  },

  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    -- Optional UI improvements
    "hrsh7th/nvim-cmp",       -- autocompletion for avante commands and mentions
    "ibhagwan/fzf-lua",       -- for file_selector provider fzf
    "stevearc/dressing.nvim", -- for input provider dressing
    "folke/snacks.nvim",      -- for input provider snacks
  },
}
