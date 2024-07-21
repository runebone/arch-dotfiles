local opt = vim.opt

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
