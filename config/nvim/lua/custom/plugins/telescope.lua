local setup = function()
    local builtin = require("telescope.builtin")

    -- Not "ff" just to type it faster with alternate fingers
    vim.keymap.set("n", "<leader>pf", builtin.find_files, {})
    vim.keymap.set("n", "<C-p>", builtin.git_files, {})
    vim.keymap.set('n', '<leader>ps', function()
        builtin.grep_string({ search = vim.fn.input("Grep > ") })
    end)
    vim.keymap.set('n', '<leader>vh', builtin.help_tags, {})
    vim.keymap.set('n', '<leader>vk', builtin.keymaps, {})
    vim.keymap.set('n', '<leader>vc', builtin.colorscheme, {})
    vim.keymap.set('n', '<leader>vs', builtin.spell_suggest, {})
    vim.keymap.set('n', '<leader>vm', builtin.marks, {})
    vim.keymap.set('n', '<leader>vb', builtin.buffers, {})
    vim.keymap.set('n', '<leader>vr', builtin.registers, {})
    vim.keymap.set('n', '<leader>vp', builtin.man_pages, {})
    vim.keymap.set('n', '<leader>rg', builtin.live_grep, {})
end

return {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = setup
}
