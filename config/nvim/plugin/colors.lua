vim.g.background_color = "dark"
vim.g.airline_theme = "base16"
vim.g.gruvbox_material_transparent_background = 2
vim.g.gruvbox_material_enable_bold = 1
vim.g.gruvbox_material_enable_italic = 1

function DisableBackground()
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

function SetBackgroundLight()
    vim.cmd("set background=light")
    vim.g.background_color = "light"
end

function SetBackgroundDark()
    vim.cmd("set background=dark")
    vim.g.background_color = "dark"
end

function ToggleLight()
    if vim.g.background_color == "dark" then
        SetBackgroundLight()
    else
        SetBackgroundDark()
    end
end

function SetGruvbox()
    SetBackgroundDark()
    vim.cmd.colorscheme("gruvbox-material")
    DisableBackground()
end

vim.keymap.set("n", "<leader>l", ":lua ToggleLight()<CR>");
vim.keymap.set("n", "<leader>d", ":lua DisableBackground()<CR>");
vim.keymap.set("n", "<leader>g", ":lua SetGruvbox()<CR>");
