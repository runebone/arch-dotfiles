vim.cmd [[
    set encoding=utf-8
    set nohlsearch
    set clipboard+=unnamedplus

    set tabstop=4
    set shiftwidth=4
    set expandtab

    set t_Co=256
    set bg=dark

    set guifont=Mononoki:h12

    set number relativenumber
    set cul
    set cuc
    set colorcolumn=80

    set splitbelow splitright

    colorscheme retrobox

    inoremap {<CR> {<CR>}<C-o>O
    inoremap [<CR> [<CR>]<C-o>O
    inoremap (<CR> (<CR>)<C-o>O

    inoremap <C-c> <Esc>

    " TODO
    nnoremap j gj
    nnoremap k gk
]]
