local M = {}
local active

-- Follow Go interface embeddings through gopls definitions, then request
-- semantic references to each method. No variable-by-variable traversal.
function M.run()
    local bufnr = vim.api.nvim_get_current_buf()
    local client = vim.lsp.get_clients({ bufnr = bufnr, name = 'gopls' })[1]
    if not client then
        vim.notify('Interface usages requires an attached gopls client', vim.log.levels.WARN)
        return
    end
    if active then active.cancel() end
    local job = {}
    active = job
    local encoding = client.offset_encoding
    local params = vim.lsp.util.make_position_params(0, encoding)
    local label = vim.fn.expand('<cword>')
    local cwd = vim.fn.getcwd()
    local request_id, timer
    function job.cancel()
        if request_id then client:cancel_request(request_id) end
        if timer then timer:stop(); timer:close(); timer = nil end
        if active == job then active = nil end
    end

    local function position(buffer, node)
        local row, col = node:range()
        local line = vim.api.nvim_buf_get_lines(buffer, row, row + 1, false)[1]
        return {
            textDocument = { uri = vim.uri_from_bufnr(buffer) },
            position = { line = row, character = vim.str_utfindex(line, encoding, col, false) },
        }
    end

    local function request(method, arguments)
        local err, result = coroutine.yield(method, arguments)
        if err then error(err.message or tostring(err), 0) end
        return result or {}
    end

    local thread = coroutine.create(function()
        local visited, methods = {}, {}
        local visit
        local function resolve(arguments)
            local locations = request('textDocument/definition', arguments)
            if locations.uri or locations.targetUri then locations = { locations } end
            for _, location in ipairs(locations) do visit(location) end
        end
        visit = function(location)
            local uri = location.uri or location.targetUri
            local start = (location.range or location.targetSelectionRange).start
            local key = uri .. ':' .. start.line .. ':' .. start.character
            if visited[key] then return end
            visited[key] = true
            local buffer = vim.uri_to_bufnr(uri)
            vim.fn.bufload(buffer)
            local line = vim.api.nvim_buf_get_lines(buffer, start.line, start.line + 1, false)[1] or ''
            local col = vim.str_byteindex(line, encoding, start.character, false)
            local parser = vim.treesitter.get_parser(buffer, 'go')
            local root = parser:parse()[1]:root()
            local node = root:named_descendant_for_range(start.line, col, start.line, col)
            while node and node:type() ~= 'type_spec' and node:type() ~= 'type_alias' do
                node = node:parent()
            end
            if not node then error('Place the cursor on a Go interface type name', 0) end
            local body = node:field('type')[1]
            if not body then error('Cannot resolve this interface type', 0) end
            if body:type() == 'type_identifier' or body:type() == 'qualified_type' then
                resolve(position(buffer, body:field('name')[1] or body))
            elseif body:type() == 'interface_type' then
                for child in body:iter_children() do
                    if child:type() == 'method_elem' then
                        methods[#methods + 1] = position(buffer, child:field('name')[1])
                    elseif child:type() == 'type_elem' then
                        local embedded = child:named_child(0)
                        if embedded and (embedded:type() == 'type_identifier' or embedded:type() == 'qualified_type') then
                            resolve(position(buffer, embedded:field('name')[1] or embedded))
                        else
                            error('Type-set constraints are not supported; use a method interface', 0)
                        end
                    end
                end
            else
                error('The selected type is not an interface', 0)
            end
        end

        resolve(params)
        if #methods == 0 then
            vim.notify('No interface methods found for ' .. label, vim.log.levels.INFO)
            return
        end
        local locations, seen = {}, {}
        for _, method in ipairs(methods) do
            method.context = { includeDeclaration = false }
            for _, location in ipairs(request('textDocument/references', method)) do
                local key = location.uri .. ':' .. vim.inspect(location.range)
                if not seen[key] then
                    seen[key] = true
                    locations[#locations + 1] = location
                end
            end
        end
        if #locations == 0 then
            vim.notify('No method references found for ' .. label, vim.log.levels.INFO)
            return
        end
        local opts = { cwd = cwd }
        local conf = require('telescope.config').values
        require('telescope.pickers').new(opts, {
            prompt_title = label .. ' · all interface method usages',
            finder = require('telescope.finders').new_table({
                results = vim.lsp.util.locations_to_items(locations, encoding),
                entry_maker = require('telescope.make_entry').gen_from_quickfix(opts),
            }),
            previewer = conf.qflist_previewer(opts),
            sorter = conf.generic_sorter(opts),
            push_cursor_on_edit = true,
        }):find()
    end)

    local function resume(...)
        if active ~= job then return end
        local ok, method, arguments = coroutine.resume(thread, ...)
        if not ok then
            job.cancel()
            vim.notify('Interface usages: ' .. tostring(method), vim.log.levels.ERROR)
        elseif coroutine.status(thread) == 'dead' then
            job.cancel()
        else
            local sent
            sent, request_id = client:request(method, arguments, function(err, result)
                vim.schedule(function()
                    if active ~= job then return end
                    request_id = nil
                    resume(err, result)
                end)
            end, bufnr)
            if not sent then
                job.cancel()
                vim.notify('Could not send interface usage request to gopls', vim.log.levels.ERROR)
            end
        end
    end
    timer = vim.uv.new_timer()
    timer:start(30000, 0, vim.schedule_wrap(function()
        if active == job then
            job.cancel()
            vim.notify('Interface usages timed out; retry once gopls is ready', vim.log.levels.WARN)
        end
    end))
    vim.notify('Finding method usages for ' .. label .. '…', vim.log.levels.INFO)
    resume()
end

return M
