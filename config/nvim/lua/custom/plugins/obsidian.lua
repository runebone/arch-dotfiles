local notes = require('config.notes')

return {
    'obsidian-nvim/obsidian.nvim',
    lazy = false,
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
        require('obsidian').setup({
            legacy_commands = false,
            workspaces = { { name = 'life-vault', path = notes.vault } },
            notes_subdir = 'base',
            new_notes_location = 'notes_subdir',
            note_id_func = function(title)
                return title and title ~= '' and title or os.date('%Y-%m-%d-%H%M%S')
            end,
            note = { template = 'base.md' },
            frontmatter = { enabled = false },
            templates = {
                folder = 'templates',
                date_format = 'YYYY-MM-DD',
                time_format = 'HH:mm',
            },
            daily_notes = {
                folder = 'daily',
                date_format = 'YYYY-MM-DD',
                template = 'daily.md',
                default_tags = {},
                workdays_only = false,
            },
            picker = { name = 'telescope.nvim' },
            ui = { enable = false },
        })

        vim.keymap.set('n', '<leader>nn', '<Cmd>Obsidian new<CR>', { desc = 'Notes: create in base' })
        vim.keymap.set('n', '<leader>no', '<Cmd>Obsidian quick_switch<CR>', { desc = 'Notes: open note' })
        vim.keymap.set('n', '<leader>ns', '<Cmd>Obsidian search<CR>', { desc = 'Notes: search text' })
        vim.keymap.set('n', '<leader>nb', '<Cmd>Obsidian backlinks<CR>', { desc = 'Notes: backlinks' })
        vim.keymap.set('n', '<leader>nd', '<Cmd>Obsidian today<CR>', { desc = 'Notes: today' })
        vim.keymap.set('n', '<leader>n[', function() notes.open_adjacent_daily(-1) end,
            { desc = 'Notes: previous existing daily' })
        vim.keymap.set('n', '<leader>n]', function() notes.open_adjacent_daily(1) end,
            { desc = 'Notes: next existing daily' })
    end,
}
