return {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    keys = {
        {
            "<leader>gd",
            function()
                if require("diffview.lib").get_current_view() then
                    vim.cmd("DiffviewClose")
                else
                    vim.cmd("DiffviewOpen")
                end
            end,
            desc = "Diffview: toggle (uncommitted changes)",
        },
        { "<leader>gD", ":DiffviewOpen main...HEAD", desc = "Diffview: review branch (edit base, then <CR>)" },
        { "<leader>gf", "<cmd>DiffviewFileHistory %<CR>", desc = "Diffview: history of current file" },
        { "<leader>gl", "<cmd>DiffviewFileHistory<CR>", desc = "Diffview: history of current branch" },
    },
    config = function()
        require("diffview").setup({
            enhanced_diff_hl = true,
            view = {
                merge_tool = { layout = "diff3_mixed" },
            },
            keymaps = {
                view = {
                    { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } },
                },
                file_panel = {
                    { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } },
                },
                file_history_panel = {
                    { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } },
                },
            },
        })
    end,
}
