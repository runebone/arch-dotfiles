local setup = function()
    require('nvim-treesitter').setup()

    -- Install parsers on startup
    require('nvim-treesitter').install({ "c", "lua", "markdown", "go", "gomod", "gowork", "json" })

    -- Enable highlighting and auto-install for supported filetypes
    vim.api.nvim_create_autocmd('FileType', {
        callback = function()
            local ft = vim.bo.filetype
            local available = require('nvim-treesitter').get_available()
            if vim.tbl_contains(available, ft) then
                require('nvim-treesitter').install({ ft })
            end
            pcall(vim.treesitter.start)
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
