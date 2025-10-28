local setup = function()
    require('nvim-treesitter.configs').setup({
        -- Equivalent to ":TSEnable highlight"
        highlight = {
            enable = true,
        };

        ensure_installed = { "c", "lua", "markdown", "go", "gomod", "gowork", "json" },
        auto_install = true,

        -- Enable movements powered by Treesitter textobjects
        textobjects = {
            move = {
                enable = true,
                set_jumps = true,
                goto_previous_start = {
                    ["[m"] = "@function.outer",
                    ["[c"] = "@class.outer",
                },
                goto_next_start = {
                    ["]m"] = "@function.outer",
                    ["]c"] = "@class.outer",
                },
                goto_previous_end = {
                    ["[M"] = "@function.outer",
                    ["[C"] = "@class.outer",
                },
                goto_next_end = {
                    ["]M"] = "@function.outer",
                    ["]C"] = "@class.outer",
                },
            },
        },
    })

    require('treesitter-context').setup({
        enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
        max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
        min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
        line_numbers = true,
        multiline_threshold = 20, -- Maximum number of lines to show for a single context
        trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
        mode = 'cursor',  -- Line used to calculate context. Choices: 'cursor', 'topline'
        -- Separator between context and content. Should be a single character string, like '-'.
        -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
        separator = nil,
        zindex = 20, -- The Z-index of the context window
        on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
    })

    vim.keymap.set("n", "<leader>th", ":TSToggle highlight<CR>");
    vim.keymap.set("n", "<leader>cc", ":TSContextToggle<CR>");
end

return {
    "nvim-treesitter/nvim-treesitter",
    dependencies = { "nvim-treesitter/nvim-treesitter-context", "nvim-treesitter/nvim-treesitter-textobjects" },
    build = ":TSUpdate",
    config = setup
}
