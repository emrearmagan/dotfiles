return {
  "karb94/neoscroll.nvim",
  event = "VeryLazy",
  config = function()
    local neoscroll = require('neoscroll')

    neoscroll.setup({
      easing = "quadratic"
    })

    local keymap = {
      ["<C-u>"] = function() neoscroll.ctrl_u({ duration = 250, easing = 'sine' }) end,
      ["<C-d>"] = function() neoscroll.ctrl_d({ duration = 250, easing = 'sine' }) end,
      ["<C-b>"] = function() neoscroll.ctrl_b({ duration = 450, easing = 'circular' }) end,
      ["<C-f>"] = function() neoscroll.ctrl_f({ duration = 450, easing = 'circular' }) end,
      ["<C-y>"] = function() neoscroll.scroll(-0.1, { move_cursor = false, duration = 100 }) end,
      ["<C-e>"] = function() neoscroll.scroll(0.1, { move_cursor = false, duration = 100 }) end,
    }

    for key, func in pairs(keymap) do
      vim.keymap.set({ "n", "v", "x" }, key, func)
    end
  end,
}
