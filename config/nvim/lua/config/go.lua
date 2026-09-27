local M = {}

function M.root(bufnr)
    bufnr = bufnr or 0
    local name = vim.api.nvim_buf_get_name(bufnr)
    return vim.fs.root(bufnr, 'go.mod') or (name ~= '' and vim.fs.dirname(name)) or vim.fn.getcwd()
end

function M.tidy()
    local root = vim.fs.root(0, 'go.mod')
    if not root then
        vim.notify('No go.mod found above this file', vim.log.levels.WARN)
        return
    end
    vim.notify('Running go mod tidy in ' .. root)
    vim.system({ 'go', 'mod', 'tidy' }, { cwd = root, text = true }, function(result)
        vim.schedule(function()
            vim.notify(result.code == 0 and 'go mod tidy finished' or result.stderr,
                result.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
        end)
    end)
end

function M.run()
    local file = vim.api.nvim_buf_get_name(0)
    if file == '' then return end
    vim.cmd.update()
    local root = M.root()
    vim.cmd('botright 12new')
    vim.fn.jobstart({ 'go', 'run', file }, { cwd = root, term = true })
    vim.cmd.startinsert()
end

function M.lint()
    if vim.fn.executable('golangci-lint') == 0 then
        vim.notify('golangci-lint is not installed', vim.log.levels.WARN)
        return
    end
    vim.cmd.update()
    local file = vim.api.nvim_buf_get_name(0)
    local target = vim.fs.root(0, 'go.mod') and vim.fs.dirname(file) or file
    require('lint').try_lint('golangcilint', {
        cwd = M.root(),
        -- The bundled linter probes go env using the editor cwd when loaded.
        -- Choose its final package argument from this buffer's module instead.
        wrap_linter = function(linter)
            if linter.args and #linter.args > 0 then
                linter.args[#linter.args] = target
            end
            return linter
        end,
    })
end

return M
