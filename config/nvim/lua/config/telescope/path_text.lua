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
    local finders = require('telescope.finders')
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
                local files, allowed, bytes = {}, {}, 0
                for entry in picker.manager:iter() do
                    local path = entry.value
                    files[#files + 1] = path
                    allowed[path] = true
                    bytes = bytes + #path + 1
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
                    finder = finders.new_async_job({
                        cwd = cwd,
                        command_generator = function(prompt)
                            if prompt == '' then return nil end
                            local args = { 'rg', '--color=never', '--no-heading',
                                '--with-filename', '--line-number', '--column',
                                '--ignore-case', '-e', M.pattern(prompt), '--' }
                            -- Bound argv size for very broad path queries. The
                            -- entry filter below preserves the frozen file set.
                            if bytes + #files * 8 < 64000 then
                                vim.list_extend(args, files)
                            else
                                args[#args + 1] = '.'
                            end
                            return args
                        end,
                        entry_maker = function(line)
                            local entry = entry_maker(line)
                            if entry and allowed[entry.filename:gsub('^%./', '')] then return entry end
                        end,
                    }),
                    sorter = require('telescope.sorters').empty(),
                    previewer = conf.grep_previewer(search_opts),
                    attach_mappings = function(bufnr, map)
                        local function back()
                            actions.close(bufnr)
                            M.run({ cwd = cwd, path_query = query })
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
