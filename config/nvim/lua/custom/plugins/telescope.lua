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

    vim.keymap.set('n', '<leader>j', function()
      local pickers = require('telescope.pickers')
      local finders = require('telescope.finders')
      local conf = require('telescope.config').values
      local make_entry = require('telescope.make_entry')

      local word = vim.fn.expand('<cword>')

      local function make_finder()
        local args = vim.deepcopy(conf.vimgrep_arguments)
        table.insert(args, '--fixed-strings')
        table.insert(args, word)
        local default_em = make_entry.gen_from_vimgrep({})
        return finders.new_oneshot_job(args, {
          entry_maker = function(line)
            local entry = default_em(line)
            if not entry then return nil end
            local rel = vim.fn.fnamemodify(entry.filename, ':.')
            entry.ordinal = rel
            return entry
          end,
        })
      end

      pickers.new({}, {
        prompt_title = "Live Grep: '" .. word .. "' | Find Files",
        finder = make_finder(),
        sorter = conf.generic_sorter({}),
        previewer = conf.grep_previewer({}),
      }):find()
    end, { desc = 'Live grep by word under cursor with filter by full path' })
end

return {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = setup
}
