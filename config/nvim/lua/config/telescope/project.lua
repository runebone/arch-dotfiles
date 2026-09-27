local M = {}

function M.root()
    local cwd = vim.fn.getcwd()
    local source = cwd
    if vim.bo.filetype == 'oil' then
        source = require('oil').get_current_dir() or cwd
    elseif vim.bo.buftype == '' and vim.api.nvim_buf_get_name(0) ~= '' then
        source = vim.api.nvim_buf_get_name(0)
    end
    -- .git may be a directory or a file (linked worktrees/submodules).
    return vim.fs.root(source, '.git') or vim.fs.root(cwd, '.git') or cwd
end

function M.title(label, cwd)
    return label .. ' [' .. vim.fn.fnamemodify(cwd, ':~') .. ']'
end

function M.options(label, opts)
    opts = vim.deepcopy(opts or {})
    opts.cwd = opts.cwd or M.root()
    opts.prompt_title = M.title(label, opts.cwd)
    return opts
end

return M
