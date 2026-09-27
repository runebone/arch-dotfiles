local M = {}

-- Keep every rg invocation below a conservative argv budget. Unlike scanning
-- cwd and filtering afterwards, no batch searches outside the frozen file set.
function M.new(opts)
    local batches, batch, bytes = {}, {}, 0
    for _, file in ipairs(opts.files) do
        local size = #file + 9 -- terminating byte and argv pointer
        if bytes + size > 48000 and #batch > 0 then
            batches[#batches + 1], batch, bytes = batch, {}, 0
        end
        batch[#batch + 1], bytes = file, bytes + size
    end
    if #batch > 0 then batches[#batches + 1] = batch end

    local generation, current = 0, nil
    local function close()
        generation = generation + 1
        if current then current:close(); current = nil end
    end
    return setmetatable({ close = close }, {
        __call = function(_, prompt, process_result, process_complete)
            close()
            local run = generation
            if prompt == '' then process_complete(); return end
            local pattern = opts.pattern(prompt)
            for _, files in ipairs(batches) do
                if run ~= generation then return end
                local args = { 'rg', '--color=never', '--no-heading',
                    '--with-filename', '--line-number', '--column',
                    '--ignore-case', '-e', pattern, '--' }
                vim.list_extend(args, files)
                local finder = require('telescope.finders').new_async_job({
                    cwd = opts.cwd,
                    command_generator = function() return vim.deepcopy(args) end,
                    entry_maker = opts.entry_maker,
                })
                current = finder
                local stopped = false
                finder(prompt, function(entry)
                    if run ~= generation then return true end
                    stopped = process_result(entry)
                    return stopped
                end, function() end)
                if run ~= generation then return end
                finder:close()
                current = nil
                if stopped then return end
            end
            if run == generation then process_complete() end
        end,
    })
end

return M
