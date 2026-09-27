local project = require('config.telescope.project')
local M = {}

function M.run(opts)
    opts = opts or {}
    local cwd = opts.cwd or project.root()
    local text = opts.text or vim.fn.expand('<cword>')
    if vim.fn.executable('rg') == 0 then
        vim.notify('Word search requires ripgrep (rg)', vim.log.levels.ERROR)
        return
    end

    local function edit(default, path_query)
        vim.ui.input({ prompt = 'Text in files: ', default = default }, function(value)
            if value and value ~= '' then
                M.run({ cwd = cwd, text = value, path_query = path_query })
            end
        end)
    end
    if text == '' then
        edit('', opts.path_query)
        return
    end

    local actions = require('telescope.actions')
    local state = require('telescope.actions.state')
    local conf = require('telescope.config').values
    local search_opts = { cwd = cwd }
    local make_entry = require('telescope.make_entry').gen_from_vimgrep(search_opts)
    require('telescope.pickers').new(search_opts, {
        prompt_title = project.title(('Files containing %q · Ctrl-E edits text'):format(text), cwd),
        results_title = 'One result per file · first matching line',
        default_text = opts.path_query,
        finder = require('telescope.finders').new_oneshot_job({
            'rg', '--color=never', '--no-heading', '--with-filename',
            '--line-number', '--column', '--ignore-case', '--fixed-strings',
            '--max-count=1', '-e', text, '--', '.',
        }, {
            cwd = cwd,
            entry_maker = function(line)
                local entry = make_entry(line)
                if entry then
                    -- Rank only the path; line text remains visible in the preview.
                    entry.ordinal = entry.filename:gsub('^%./', '')
                end
                return entry
            end,
        }),
        sorter = conf.generic_sorter(search_opts),
        previewer = conf.grep_previewer(search_opts),
        attach_mappings = function(bufnr, map)
            local function change_text()
                local path_query = state.get_current_line()
                actions.close(bufnr)
                vim.schedule(function() edit(text, path_query) end)
            end
            map('i', '<C-e>', change_text)
            map('n', '<C-e>', change_text)
            return true
        end,
    }):find()
end

return M
