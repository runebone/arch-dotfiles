--[[
-- Setup initial configuration,
-- 
-- Primarily just download and execute lazy.nvim
--]]
vim.g.mapleader = " "

vim.opt.termguicolors = true -- Needed here before nvim-colorizer

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    vim.fn.system {
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    }
end

-- Add lazy to the `runtimepath`, this allows us to `require` it.
---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

-- Set up lazy, and load my `lua/custom/plugins/` folder
require("lazy").setup({
    import = "custom/plugins",
    change_detection = { notify = false },
})

-- Other configuration

SetGruvbox()

vim.cmd [[ au TextYankPost * silent! lua vim.highlight.on_yank { timeout=100 } ]]

vim.keymap.set("n", "<leader>x", "<cmd>.lua<CR>", { desc = "Execute the current line" })

function ToggleWrap()
    if vim.o.wrap then
        vim.opt.wrap = false
    else
        vim.opt.wrap = true
    end
end

vim.keymap.set("n", "<leader>wl", "<cmd>lua ToggleWrap()<CR>") -- Because I have "wr" and "wa" bindings
vim.keymap.set("n", "<leader>h", "<cmd>nohlsearch<CR>")
