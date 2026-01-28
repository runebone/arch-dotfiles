local setup = function()
    require("telescope").setup {
        pickers = {
            find_files = {
                theme = "ivy"
            }
        },
        extensions = {
            fzf = {}
        }
    }
    require("telescope").load_extension("fzf")

    local builtin = require("telescope.builtin")

    vim.keymap.set("n", "<leader>ep", function()
        builtin.find_files {
            cwd = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy")
        }
    end)

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

    local multigrep = require("config.telescope.multigrep")
    vim.keymap.set("n", "<leader>fg", multigrep.run, {})

    -- Visual mode: live_grep with selected text as default
    local function get_last_visual_selection()
        local _, ls, cs = unpack(vim.fn.getpos("'<"))
        local _, le, ce = unpack(vim.fn.getpos("'>"))
        if ls == 0 or le == 0 then return '' end
        local lines = vim.fn.getline(ls, le)
        if #lines == 0 then return '' end
        lines[#lines] = string.sub(lines[#lines], 1, ce)
        lines[1] = string.sub(lines[1], cs)
        local text = table.concat(lines, ' ')
        return text
    end

    vim.keymap.set('v', '<leader>rg', function()
        -- exit visual so marks '< and '>' are set to current selection
        local esc = vim.api.nvim_replace_termcodes('<Esc>', true, false, true)
        vim.api.nvim_feedkeys(esc, 'nx', false)
        vim.schedule(function()
            local text = get_last_visual_selection()
            if text == '' then
                builtin.live_grep()
            else
                builtin.live_grep({ default_text = text })
            end
        end)
    end, { desc = 'Telescope live_grep with visual selection', silent = true })

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
    dependencies = {
        "nvim-lua/plenary.nvim",
        { "nvim-telescope/telescope-fzf-native.nvim", build = "make" }
    },
    config = setup
}
