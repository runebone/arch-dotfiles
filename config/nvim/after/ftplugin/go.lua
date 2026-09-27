local go = require('config.go')
vim.keymap.set('n', '<leader>ta', go.alternate, { buffer = true, desc = 'Go: switch source/test file' })
vim.keymap.set('n', '<leader>rf', go.tidy, { buffer = true, desc = 'Go mod tidy in nearest module' })
vim.keymap.set('n', '<leader>x', go.run, { buffer = true, desc = 'Run current Go package' })
vim.keymap.set('n', '<leader>rl', go.lint, { buffer = true, desc = 'Lint current Go package' })

vim.opt_local.expandtab = false
vim.opt_local.shiftwidth = 4
vim.opt_local.tabstop = 4
