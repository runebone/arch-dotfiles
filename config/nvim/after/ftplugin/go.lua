vim.keymap.set("n", "<leader>rf", ":!go mod tidy<CR>:LspRestart<CR>", { desc = "Go mod tidy and restart LSP" })
vim.keymap.set("n", "<leader>x", ":!go run %<CR>", { desc = "Execute current go file" })
