return {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    vim.keymap.set("n", "<leader>td", ":TodoTelescope<CR>")
  }
}
