local M = {}
local last_task, running, terminal

local function package_info()
    local file = vim.api.nvim_buf_get_name(0)
    if file == '' or vim.bo.filetype ~= 'go' then
        vim.notify('Open a Go file first', vim.log.levels.WARN)
        return
    end
    local dir = vim.fs.dirname(file)
    local root = require('config.go').root()
    local relative = vim.fs.relpath(root, dir)
    return root, relative == '.' and '.' or './' .. relative, dir
end

function M.diagnostics(lines, directory, root)
    local items = {}
    for _, line in ipairs(lines) do
        line = line:gsub('\27%[[%d;]*m', ''):gsub('\r$', '')
        local file, row, col, message = line:match('^%s*(.-%.go):(%d+):(%d+):%s*(.*)')
        if not file then
            file, row, message = line:match('^%s*(.-%.go):(%d+):%s*(.*)')
        end
        if file then
            if not vim.startswith(file, '/') then
                local from_root = root and vim.fs.joinpath(root, file)
                file = from_root and vim.uv.fs_stat(from_root) and from_root or vim.fs.joinpath(directory, file)
            end
            items[#items + 1] = { filename = file, lnum = tonumber(row), col = tonumber(col) or 1, text = message }
        end
    end
    return items
end

local function launch(task)
    if running then
        vim.notify('A Go task is still running; stop it with Ctrl-C in its terminal first', vim.log.levels.WARN)
        return
    end
    local window = terminal and vim.fn.bufwinid(terminal) or -1
    if window ~= -1 then
        vim.api.nvim_set_current_win(window)
        vim.cmd.enew()
    else
        vim.cmd('botright 12new')
    end
    local old_terminal = terminal
    terminal = vim.api.nvim_get_current_buf()
    if old_terminal and vim.api.nvim_buf_is_valid(old_terminal) then
        vim.api.nvim_buf_delete(old_terminal, { force = true })
    end
    local output = {}
    local function collect(_, lines)
        vim.list_extend(output, lines)
    end
    local id = vim.fn.jobstart(task.argv, {
        cwd = task.cwd,
        term = true,
        stdout_buffered = true,
        on_stdout = collect,
        on_exit = function(_, code)
            vim.schedule(function()
                running = nil
                local items = M.diagnostics(output, task.package_dir, task.cwd)
                vim.fn.setqflist({}, ' ', { title = table.concat(task.argv, ' '), items = items })
                vim.notify(('Go task %s (%d locations in quickfix)'):format(
                    code == 0 and 'passed' or ('exited with ' .. code), #items),
                    code == 0 and vim.log.levels.INFO or vim.log.levels.WARN)
            end)
        end,
    })
    if id <= 0 then
        vim.notify('Could not start Go task', vim.log.levels.ERROR)
        return
    end
    running, last_task = id, task
    vim.cmd.startinsert()
end

function M.run_package()
    local root, package, directory = package_info()
    if not root then return end
    vim.cmd.update()
    launch({ argv = { 'go', 'run', package }, cwd = root, package_dir = directory })
end

function M.test_package()
    local root, package, directory = package_info()
    if not root then return end
    vim.cmd.update()
    launch({ argv = { 'go', 'test', '-count=1', package }, cwd = root, package_dir = directory })
end

function M.test_nearest()
    local root, package, directory = package_info()
    if not root then return end
    local ok, node = pcall(vim.treesitter.get_node)
    if not ok then
        vim.notify('Nearest test needs the Go Treesitter parser', vim.log.levels.WARN)
        return
    end
    while node and node:type() ~= 'function_declaration' do node = node:parent() end
    local name_node = node and node:field('name')[1]
    local name = name_node and vim.treesitter.get_node_text(name_node, 0)
    if not name or not name:match('^Test') or not vim.api.nvim_buf_get_name(0):match('_test%.go$') then
        vim.notify('Place the cursor inside a Test function in a _test.go file', vim.log.levels.WARN)
        return
    end
    vim.cmd.update()
    -- Run the enclosing test, including its subtests. Build tags remain opt-in.
    launch({ argv = { 'go', 'test', '-count=1', '-run', '^' .. name .. '$', package },
        cwd = root, package_dir = directory })
end

function M.rerun()
    if not last_task then
        vim.notify('No previous Go task in this session', vim.log.levels.INFO)
        return
    end
    if vim.bo.buftype == '' then vim.cmd.update() end
    launch(last_task)
end

return M
