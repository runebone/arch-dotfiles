return {
    'mfussenegger/nvim-lint',
    config = function()
        -- Run with Space rl; gopls still provides live diagnostics.
        require('lint').linters_by_ft = { go = { 'golangcilint' } }
    end,
}
