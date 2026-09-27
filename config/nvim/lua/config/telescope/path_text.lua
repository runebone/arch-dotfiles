local M = {}

-- Escape literal characters before building a case-insensitive subsequence regex.
function M.pattern(text)
    local chars = vim.fn.split(text, '\\zs')
    for i, char in ipairs(chars) do
        chars[i] = vim.fn.escape(char, [[\.^$|?*+()[]{}]])
    end
    return table.concat(chars, '.*?')
end

function M.run(opts)
    opts = opts or {}
    local cwd = opts.cwd or vim.fn.getcwd()
    local actions = require('telescope.actions')
    local state = require('telescope.actions.state')
    local conf = require('telescope.config').values
    local make_entry = require('telescope.make_entry')
    local pickers = require('telescope.pickers')

    if vim.fn.executable('rg') == 0 then
        vim.notify('Path/text search requires ripgrep (rg)', vim.log.levels.ERROR)
        return
    end

    local completed_query
    require('telescope.builtin').find_files({
        cwd = cwd,
        default_text = opts.path_query,
        find_command = { 'rg', '--files', '--color=never' },
        prompt_title = 'File paths → Enter locks all matches',
        on_complete = { function(picker) completed_query = picker:_get_prompt() end },
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                local picker = state.get_current_picker(prompt_bufnr)
                local query = state.get_current_line()
                if completed_query ~= query then
                    vim.notify('File filtering is still running; press Enter when it finishes', vim.log.levels.INFO)
                    return
                end
                local files = {}
                for entry in picker.manager:iter() do
                    local path = entry.value
                    files[#files + 1] = path
                end
                if #files == 0 then
                    vim.notify('No matching files', vim.log.levels.INFO)
                    return
                end
                actions.close(prompt_bufnr)
                local search_opts = { cwd = cwd }
                local entry_maker = make_entry.gen_from_vimgrep(search_opts)
                pickers.new(search_opts, {
                    prompt_title = ('Text in %d files [%s]'):format(#files, query),
                    debounce = 100,
                    default_text = opts.text_query,
                    finder = require('config.telescope.scoped_grep').new({
                        cwd = cwd,
                        files = files,
                        pattern = M.pattern,
                        entry_maker = entry_maker,
                    }),
                    sorter = require('telescope.sorters').empty(),
                    previewer = conf.grep_previewer(search_opts),
                    attach_mappings = function(bufnr, map)
                        local function back()
                            local text_query = state.get_current_line()
                            actions.close(bufnr)
                            M.run({ cwd = cwd, path_query = query, text_query = text_query })
                        end
                        map('i', '<C-b>', back)
                        map('n', '<C-b>', back)
                        return true
                    end,
                }):find()
            end)
            return true
        end,
    })
end

return M
