return {
    { "tpope/vim-fugitive" },
    { "tpope/vim-surround" },
    { "tpope/vim-repeat" },
    { "Yggdroot/indentLine", config = function()
        vim.g.indentLine_setConceal = 0
    end },
    -- { "vim-airline/vim-airline" },
    -- { "vim-airline/vim-airline-themes" },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("lualine").setup()
        end
    },
    { "fatih/vim-go" },
    { "norcalli/nvim-colorizer.lua", config = function()
        require("colorizer").setup({ "*" }, { names = false })
    end },
}
