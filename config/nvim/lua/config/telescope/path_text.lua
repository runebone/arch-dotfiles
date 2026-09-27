local project = require('config.telescope.project')
local M = {}

-- Escape literal characters before building a case-insensitive subsequence regex.
function M.pattern(text, literal)
    if literal then return vim.fn.escape(text, [[\.^$|?*+()[]{}]]) end
    local chars = vim.fn.split(text, '\\zs')
    for i, char in ipairs(chars) do
        chars[i] = vim.fn.escape(char, [[\.^$|?*+()[]{}]])
    end
    return table.concat(chars, '.*?')
end

function M.run(opts)
    opts = opts or {}
    local cwd = opts.cwd or project.root()
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
        prompt_title = project.title('File paths → Enter locks all matches', cwd),
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
                local literal = opts.literal or false
                local function title()
                    return project.title(('%s text in %d files [%s] · Ctrl-F toggles'):format(
                        literal and 'Literal' or 'Fuzzy', #files, query), cwd)
                end
                local function finder()
                    -- Capture the mode so a cancelled search cannot change modes mid-run.
                    local mode = literal
                    return require('config.telescope.scoped_grep').new({
                        cwd = cwd,
                        files = files,
                        pattern = function(text) return M.pattern(text, mode) end,
                        entry_maker = entry_maker,
                    })
                end
                pickers.new(search_opts, {
                    prompt_title = title(),
                    debounce = 100,
                    default_text = opts.text_query,
                    finder = finder(),
                    sorter = require('telescope.sorters').empty(),
                    previewer = conf.grep_previewer(search_opts),
                    attach_mappings = function(bufnr, map)
                        local function back()
                            local text_query = state.get_current_line()
                            actions.close(bufnr)
                            M.run({ cwd = cwd, path_query = query, text_query = text_query, literal = literal })
                        end
                        local function toggle()
                            literal = not literal
                            local current = state.get_current_picker(bufnr)
                            current.prompt_title = title()
                            if current.layout.prompt.border then
                                current.layout.prompt.border:change_title(current.prompt_title)
                            end
                            current:refresh(finder(), { reset_prompt = false })
                        end
                        map('i', '<C-b>', back)
                        map('n', '<C-b>', back)
                        map('i', '<C-f>', toggle)
                        map('n', '<C-f>', toggle)
                        return true
                    end,
                }):find()
            end)
            return true
        end,
    })
end

return M
