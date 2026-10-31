local M = {}

M.vault = os.getenv('LIFE_VAULT_PATH') or '/home/rukost/Personal/life-vault'

-- The daily-note filename is sortable, so compare names without parsing dates.
function M.adjacent_daily(root, current_path, direction)
    assert(direction == -1 or direction == 1, 'direction must be -1 or 1')
    local current_date = current_path:match('/daily/(%d%d%d%d%-%d%d%-%d%d)%.md$')
    local anchor = current_date or os.date('%Y-%m-%d')
    local chosen
    for _, path in ipairs(vim.fn.globpath(root .. '/daily', '*.md', false, true)) do
        local date = path:match('/(%d%d%d%d%-%d%d%-%d%d)%.md$')
        if date and ((direction == -1 and (date < anchor or (not current_date and date == anchor)))
            or (direction == 1 and date > anchor)) then
            if not chosen or (direction == -1 and path > chosen) or (direction == 1 and path < chosen) then
                chosen = path
            end
        end
    end
    return chosen
end

function M.open_adjacent_daily(direction)
    local path = M.adjacent_daily(M.vault, vim.api.nvim_buf_get_name(0), direction)
    if not path then
        vim.notify('No ' .. (direction == -1 and 'previous' or 'next') .. ' daily note', vim.log.levels.INFO)
        return
    end
    vim.cmd.edit(vim.fn.fnameescape(path))
end

return M
