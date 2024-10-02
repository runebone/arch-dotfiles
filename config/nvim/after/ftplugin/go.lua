vim.keymap.set("n", "<leader>rf", ":!go mod tidy<CR>:LspRestart<CR>", { desc = "Go mod tidy and restart LSP" })
