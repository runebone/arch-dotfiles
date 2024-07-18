local setup = function()
    local tr = require("trouble")

    tr.setup({
        icons = false,
    })

    vim.keymap.set("n", "<leader>tt", function()
        tr.toggle()
    end)

    vim.keymap.set("n", "]t", function()
        tr.next({skip_groups = true, jump = true});
    end)

    vim.keymap.set("n", "[t", function()
        tr.previous({skip_groups = true, jump = true});
    end)
end

return {
    "folke/trouble.nvim",
    config = setup
}
