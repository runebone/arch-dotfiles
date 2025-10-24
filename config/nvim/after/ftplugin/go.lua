vim.keymap.set("n", "<leader>rf", ":!go mod tidy<CR>:LspRestart<CR>", { desc = "Go mod tidy and restart LSP" })
vim.keymap.set("n", "<leader>x", ":!go run %<CR>", { desc = "Execute current go file" })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  callback = function()
    vim.opt_local.expandtab = false    -- использовать табы вместо пробелов
    vim.opt_local.shiftwidth = 4      -- ширина отступа
    vim.opt_local.tabstop = 4         -- ширина таба
  end,
})
