local M = {}
local ns = vim.api.nvim_create_namespace('refactor_tasks')
local stores = {}
local project = require('config.telescope.project')

local function current_root()
    if vim.bo.buftype == 'quickfix' then
        local context = vim.fn.getqflist({ context = 0 }).context
        if type(context) == 'table' and context.refactor_root then
            return context.refactor_root
        end
    end
    return project.root()
end

local function state_path(root)
    return vim.fn.stdpath('state') .. '/refactor/' .. vim.fn.sha256(root) .. '.json'
end

local function store(root)
    root = root or current_root()
    if stores[root] then return stores[root] end
    local s = { root = root, items = {} }
    local path = state_path(root)
    if vim.fn.filereadable(path) == 1 then
        local ok, data = pcall(function()
            return vim.json.decode(table.concat(vim.fn.readfile(path), '\n'))
        end)
        if not ok or type(data) ~= 'table' or data.version ~= 1 or data.root ~= root
            or type(data.items) ~= 'table' then
            error('Cannot read refactor tasks: ' .. path .. ' (file left untouched)')
        end
        for _, item in ipairs(data.items) do
            assert(type(item) == 'table' and type(item.id) == 'string'
                and type(item.path) == 'string' and type(item.line) == 'number'
                and type(item.source) == 'string' and type(item.note) == 'string',
                'Invalid refactor task in ' .. path .. ' (file left untouched)')
        end
        s.items = data.items
    end
    stores[root] = s
    return s
end

local function locate(item)
    local buf = vim.fn.bufnr(item.path)
    if buf == -1 or not vim.api.nvim_buf_is_loaded(buf) then return end
    if item.buf == buf and item.mark then
        local pos = vim.api.nvim_buf_get_extmark_by_id(buf, ns, item.mark, {})
        if #pos > 0 then
            item.line = pos[1] + 1
            return
        end
    end
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    -- Relocate only an unambiguous source match after reopening/external edits.
    if lines[item.line] ~= item.source and item.source:match('%S') then
        local match
        for i, line in ipairs(lines) do
            if line == item.source then
                if match then match = nil; break end
                match = i
            end
        end
        if match then item.line = match end
    end
    item.line = math.max(1, math.min(item.line, #lines))
    item.buf = buf
    item.mark = vim.api.nvim_buf_set_extmark(buf, ns, item.line - 1, 0, { right_gravity = true })
end

local function sync(s)
    for _, item in ipairs(s.items) do locate(item) end
end

local function save(s)
    sync(s)
    local items = {}
    for _, item in ipairs(s.items) do
        local source = item.source
        if item.buf and vim.api.nvim_buf_is_loaded(item.buf) then
            source = vim.api.nvim_buf_get_lines(item.buf, item.line - 1, item.line, false)[1] or source
        end
        items[#items + 1] = { id = item.id, path = item.path, line = item.line,
            source = source, note = item.note, done = item.done or false }
    end
    local path = state_path(s.root)
    vim.fn.mkdir(vim.fs.dirname(path), 'p')
    local temporary = path .. '.' .. vim.fn.getpid() .. '.tmp'
    vim.fn.writefile({ vim.json.encode({ version = 1, root = s.root, items = items }) }, temporary)
    assert(vim.uv.fs_rename(temporary, path))
end

local function qf_items(s)
    sync(s)
    local items = {}
    for _, item in ipairs(s.items) do
        if not item.done then
            items[#items + 1] = { filename = item.path, lnum = item.line, col = 1,
                text = item.note ~= '' and item.note or item.source, user_data = { refactor_id = item.id } }
        end
    end
    return items
end

local function changed(s)
    save(s)
    if s.qfid and vim.fn.getqflist({ id = s.qfid }).id == s.qfid then
        vim.fn.setqflist({}, 'r', { id = s.qfid, items = qf_items(s) })
    end
end

function M.list(root, include_done)
    local s = store(root)
    sync(s)
    return vim.tbl_filter(function(item) return include_done or not item.done end, s.items)
end

function M.add(note)
    local path = vim.api.nvim_buf_get_name(0)
    if vim.bo.buftype ~= '' or path == '' then
        vim.notify('Refactor: open a file first', vim.log.levels.WARN)
        return
    end
    local s = store()
    sync(s)
    local line = vim.fn.line('.')
    for _, item in ipairs(s.items) do
        if item.path == path and item.line == line then
            item.done = false
            if note ~= nil then item.note = note end
            changed(s)
            vim.notify('Refactor: location already collected; task is pending')
            return item
        end
    end
    local item = { id = tostring(vim.fn.getpid()) .. ':' .. tostring(vim.uv.hrtime()),
        path = path, line = line, source = vim.fn.getline('.'), note = note or '', done = false }
    s.items[#s.items + 1] = item
    changed(s)
    vim.notify('Refactor: location added')
    return item
end

function M.add_note()
    local buf, cursor = vim.api.nvim_get_current_buf(), vim.api.nvim_win_get_cursor(0)
    vim.ui.input({ prompt = 'Refactor note: ' }, function(note)
        if note == nil then return end
        if vim.api.nvim_get_current_buf() ~= buf or vim.fn.line('.') ~= cursor[1] then
            vim.notify('Refactor: location changed; add the note again', vim.log.levels.WARN)
            return
        end
        M.add(note)
    end)
end

function M.toggle(root, id)
    local s = store(root)
    for _, item in ipairs(s.items) do
        if item.id == id then item.done = not item.done; changed(s); return end
    end
end

function M.remove(root, id)
    local s = store(root)
    for i, item in ipairs(s.items) do
        if item.id == id then
            if item.buf and item.mark and vim.api.nvim_buf_is_valid(item.buf) then
                pcall(vim.api.nvim_buf_del_extmark, item.buf, ns, item.mark)
            end
            table.remove(s.items, i)
            changed(s)
            return
        end
    end
end

function M.done()
    local root, id
    if vim.bo.buftype == 'quickfix' then
        local qf = vim.fn.getqflist({ context = 0, items = 0 })
        local item = qf.items[vim.fn.line('.')]
        if type(qf.context) == 'table' and qf.context.refactor_root and item then
            root = qf.context.refactor_root
            id = type(item.user_data) == 'table' and item.user_data.refactor_id or nil
        end
    else
        root = project.root()
        for _, item in ipairs(M.list(root)) do
            if item.path == vim.api.nvim_buf_get_name(0) and item.line == vim.fn.line('.') then
                id = item.id
                break
            end
        end
    end
    if not id then vim.notify('Refactor: no pending task here'); return end
    for _, item in ipairs(store(root).items) do
        if item.id == id then item.done = true; changed(store(root)); break end
    end
    vim.notify('Refactor: task completed')
end

function M.quickfix()
    local s = store()
    vim.fn.setqflist({}, ' ', { title = 'Refactor: ' .. s.root,
        context = { refactor_root = s.root }, items = qf_items(s) })
    s.qfid = vim.fn.getqflist({ id = 0 }).id
    vim.cmd.copen()
end

function M.picker()
    local root = current_root()
    local show_done = false
    local pickers, finders = require('telescope.pickers'), require('telescope.finders')
    local conf = require('telescope.config').values
    local actions, state = require('telescope.actions'), require('telescope.actions.state')
    local function finder()
        return finders.new_table({ results = M.list(root, show_done), entry_maker = function(item)
            local relative = item.path:sub(1, #root + 1) == root .. '/'
                and item.path:sub(#root + 2) or item.path
            local label = string.format('[%s] %s:%d  %s', item.done and 'x' or ' ', relative,
                item.line, item.note ~= '' and item.note or item.source)
            return { value = item, display = label, ordinal = label, filename = item.path, lnum = item.line }
        end })
    end
    pickers.new({}, {
        prompt_title = 'Refactor tasks [' .. root .. ']',
        results_title = 'Pending | C-d: done/undo | C-x: delete | C-a: all/pending',
        finder = finder(), sorter = conf.generic_sorter({}), previewer = conf.qflist_previewer({}),
        attach_mappings = function(buf, map)
            local function refresh()
                local picker = state.get_current_picker(buf)
                picker.results_title = (show_done and 'All' or 'Pending')
                    .. ' | C-d: done/undo | C-x: delete | C-a: all/pending'
                picker:refresh(finder(), { reset_prompt = false })
            end
            local function selected(fn)
                local entry = state.get_selected_entry()
                if entry then fn(root, entry.value.id); refresh() end
            end
            for _, mode in ipairs({ 'i', 'n' }) do
                map(mode, '<C-d>', function() selected(M.toggle) end)
                map(mode, '<C-x>', function() selected(M.remove) end)
                map(mode, '<C-a>', function() show_done = not show_done; refresh() end)
            end
            actions.select_default:replace(function()
                local entry = state.get_selected_entry()
                if not entry then return end
                actions.close(buf)
                vim.cmd.edit(vim.fn.fnameescape(entry.value.path))
                locate(entry.value)
                vim.api.nvim_win_set_cursor(0, { entry.value.line, 0 })
                vim.cmd('normal! zvzz')
            end)
            return true
        end,
    }):find()
end

function M.setup()
    local group = vim.api.nvim_create_augroup('RefactorTasks', { clear = true })
    vim.api.nvim_create_autocmd('BufReadPost', { group = group, callback = function(event)
        local path = vim.api.nvim_buf_get_name(event.buf)
        local root = vim.fs.root(path, '.git') or vim.fn.getcwd()
        sync(store(root))
    end })
    vim.api.nvim_create_autocmd({ 'BufWritePost', 'VimLeavePre' }, { group = group, callback = function()
        for _, s in pairs(stores) do
            if #s.items > 0 then changed(s) end
        end
    end })
    sync(store())
    local mappings = {
        ['<leader>qa'] = { M.add, 'Add location' },
        ['<leader>qn'] = { M.add_note, 'Add location with note' },
        ['<leader>qq'] = { M.picker, 'Browse tasks' },
        ['<leader>qf'] = { M.quickfix, 'Pending tasks to quickfix' },
        ['<leader>qd'] = { M.done, 'Mark task done' },
    }
    for lhs, mapping in pairs(mappings) do
        vim.keymap.set('n', lhs, mapping[1], { desc = 'Refactor: ' .. mapping[2] })
    end
    if vim.fn.maparg('<C-q>', 'n') == '' then
        vim.keymap.set('n', '<C-q>', M.add, { desc = 'Refactor: add location' })
    end
end

return M
