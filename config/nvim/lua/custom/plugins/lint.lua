local setup = function()
    local lint = require('lint')
    lint.linters_by_ft = {
        go = { "golangcilint" }
    }

    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        callback = function()
            require("lint").try_lint()
        end,
    })
end

return {
    {
        "mfussenegger/nvim-lint",
        config = setup
    },
    {
        "stevearc/conform.nvim",
        opts = {},
    }
}
