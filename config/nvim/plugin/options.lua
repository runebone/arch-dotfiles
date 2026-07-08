local opt = vim.opt

-- Copy yanks to the local clipboard over SSH/tmux via OSC 52 terminal escapes.
-- X11 forwarding loses the selection when nvim exits; OSC 52 does not.
-- Paste reads the last yank instead of querying the terminal: most terminals
-- (e.g. Alacritty) never answer an OSC 52 read, so the query hangs forever.
local osc52 = require("vim.ui.clipboard.osc52")
local function paste(reg)
  return function()
    local str = vim.fn.getreg(reg)
    return vim.fn.split(str, "\n", true)
  end
end
vim.g.clipboard = {
  name = "OSC 52",
  copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
  paste = { ["+"] = paste('"'), ["*"] = paste('"') },
}

opt.clipboard = "unnamedplus"

opt.inccommand = "split"
opt.smartcase = true
opt.ignorecase = true

opt.number = true
opt.relativenumber = true
opt.splitbelow = true
opt.splitright = true

opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
-- opt.smartindent = true

opt.signcolumn = "yes"

-- Don't have `o` add a comment
-- opt.formatoptions:remove("o")

opt.wrap = true
opt.linebreak = true

opt.termguicolors = true

-- Fix emoji rendering
opt.ambiwidth = "single"
