local root = assert(os.getenv('NVIM_TEST_ROOT'))
local temporary = assert(os.getenv('NVIM_TEST_TMP'))
vim.g.mapleader = ' '
vim.opt.rtp:prepend(root)
vim.opt.rtp:append(vim.fn.stdpath('data') .. '/site')
for _, name in ipairs({ 'plenary.nvim', 'telescope.nvim', 'telescope-fzf-native.nvim' }) do
    vim.opt.rtp:append(vim.fn.stdpath('data') .. '/lazy/' .. name)
end
require('telescope').setup({ defaults = { preview = false, history = { path = temporary .. '/history' } } })
return { root = root, temporary = temporary }
