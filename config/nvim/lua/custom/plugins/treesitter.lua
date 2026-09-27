local setup = function()
    require('nvim-treesitter').setup()

    local ts = require('nvim-treesitter')
    local pending = {}
    vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('CustomTreesitter', { clear = true }),
        callback = function(event)
            local lang = vim.treesitter.language.get_lang(event.match)
            if not lang then return end
            local function start(buffer)
                if vim.api.nvim_buf_is_valid(buffer)
                    and vim.treesitter.language.get_lang(vim.bo[buffer].filetype) == lang then
                    pcall(vim.treesitter.start, buffer, lang)
                end
            end
            if vim.tbl_contains(ts.get_installed(), lang) then
                start(event.buf)
            elseif vim.tbl_contains(ts.get_available(), lang) then
                if pending[lang] then
                    pending[lang][event.buf] = true
                    return
                end
                pending[lang] = { [event.buf] = true }
                ts.install({ lang }):await(function()
                    vim.schedule(function()
                        local buffers = pending[lang] or {}
                        pending[lang] = nil
                        for buffer in pairs(buffers) do start(buffer) end
                    end)
                end)
            end
        end,
    })

    require('treesitter-context').setup({
        enable = true,
        max_lines = 0,
        min_window_height = 0,
        line_numbers = true,
        multiline_threshold = 20,
        trim_scope = 'outer',
        mode = 'cursor',
        separator = nil,
        zindex = 20,
        on_attach = nil,
    })

    require('nvim-treesitter-textobjects').setup({
        select = { lookahead = true },
    })
    local select = require('nvim-treesitter-textobjects.select')
    for key, capture in pairs({
        ['if'] = '@function.inner',
        ['af'] = '@function.outer',
        ['ia'] = '@parameter.inner',
        ['aa'] = '@parameter.outer',
    }) do
        vim.keymap.set({ 'x', 'o' }, key, function()
            select.select_textobject(capture, 'textobjects')
        end, { desc = 'Select ' .. capture })
    end

    local move = require("nvim-treesitter-textobjects.move")
    vim.keymap.set({ "n", "x", "o" }, "[m", function() move.goto_previous_start("@function.outer", "textobjects") end)
    vim.keymap.set({ "n", "x", "o" }, "[c", function() move.goto_previous_start("@class.outer", "textobjects") end)
    vim.keymap.set({ "n", "x", "o" }, "]m", function() move.goto_next_start("@function.outer", "textobjects") end)
    vim.keymap.set({ "n", "x", "o" }, "]c", function() move.goto_next_start("@class.outer", "textobjects") end)
    vim.keymap.set({ "n", "x", "o" }, "[M", function() move.goto_previous_end("@function.outer", "textobjects") end)
    vim.keymap.set({ "n", "x", "o" }, "[C", function() move.goto_previous_end("@class.outer", "textobjects") end)
    vim.keymap.set({ "n", "x", "o" }, "]M", function() move.goto_next_end("@function.outer", "textobjects") end)
    vim.keymap.set({ "n", "x", "o" }, "]C", function() move.goto_next_end("@class.outer", "textobjects") end)

    vim.keymap.set("n", "<leader>cc", ":TSContextToggle<CR>")
end

return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    dependencies = {
        "nvim-treesitter/nvim-treesitter-context",
        { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
    },
    build = ":TSUpdate",
    config = setup
}
