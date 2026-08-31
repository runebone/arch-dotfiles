return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        local gs = require("gitsigns")

        gs.setup({
            on_attach = function(bufnr)
                local function map(mode, lhs, rhs, desc)
                    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
                end

                -- Hunk navigation; falls back to native motions inside a diff view.
                map("n", "]c", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "]c", bang = true })
                    else
                        gs.nav_hunk("next")
                    end
                end, "Next hunk")

                map("n", "[c", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "[c", bang = true })
                    else
                        gs.nav_hunk("prev")
                    end
                end, "Previous hunk")

                map("n", "<leader>gp", gs.preview_hunk, "Gitsigns: preview hunk")
                map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Gitsigns: blame line")
                map("n", "<leader>gB", gs.toggle_current_line_blame, "Gitsigns: toggle inline blame")
                map("n", "<leader>gr", gs.reset_hunk, "Gitsigns: reset hunk")
                map("v", "<leader>gr", function()
                    gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end, "Gitsigns: reset selected hunk")
            end,
        })
    end,
}
