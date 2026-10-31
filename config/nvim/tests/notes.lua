local env = dofile(os.getenv('NVIM_TEST_ROOT') .. '/tests/bootstrap.lua')
local plugin_path = os.getenv('NVIM_TEST_OBSIDIAN_PLUGIN') or (vim.fn.stdpath('data') .. '/lazy/obsidian.nvim')
vim.opt.rtp:append(plugin_path)
vim.cmd('filetype on')

local vault = env.temporary .. '/vault'
for _, dir in ipairs({ 'base', 'daily', 'templates', 'z-tags' }) do
    vim.fn.mkdir(vault .. '/' .. dir, 'p')
end
vim.fn.writefile({ '---', 'date: {{date}} {{time}}', '---', 'Tags and associations: ' }, vault .. '/templates/base.md')
vim.fn.writefile({ '---', 'date: {{date}} {{time}}', '---', 'Tags and associations: [[daily]]' }, vault .. '/templates/daily.md')
vim.fn.writefile({ 'Tags and associations: [[exercise]]' }, vault .. '/base/exercise list.md')
vim.fn.writefile({ 'Tags and associations: [[exercise]]' }, vault .. '/base/other exercises.md')
vim.fn.writefile({}, vault .. '/z-tags/exercise.md')
vim.fn.setenv('LIFE_VAULT_PATH', vault)

local notes = require('config.notes')
local first = vault .. '/daily/2026-10-01.md'
local second = vault .. '/daily/2026-10-10.md'
local third = vault .. '/daily/2026-10-20.md'
for _, path in ipairs({ first, second, third }) do vim.fn.writefile({ 'daily' }, path) end

assert(notes.adjacent_daily(vault, second, -1) == first, 'previous existing daily')
assert(notes.adjacent_daily(vault, second, 1) == third, 'next existing daily')
assert(notes.adjacent_daily(vault, first, -1) == nil, 'no previous note')
assert(notes.adjacent_daily(vault, third, 1) == nil, 'no next note')
assert(notes.adjacent_daily(vault, vault .. '/base/exercise list.md', -1) == third,
    'from non-daily file, search back from today')

local spec = require('custom.plugins.obsidian')
spec.config()
dofile(plugin_path .. '/plugin/obsidian.lua')
local cfg = Obsidian.opts
assert(cfg.notes_subdir == 'base' and cfg.new_notes_location == 'notes_subdir')
assert(cfg.daily_notes.folder == 'daily' and cfg.daily_notes.workdays_only == false)
assert(cfg.frontmatter.enabled == false)
assert(cfg.note.template == 'base.md' and cfg.daily_notes.template == 'daily.md')
assert(vim.fn.maparg('<leader>nn', 'n') ~= '')
assert(vim.fn.maparg('<leader>no', 'n') ~= '')
assert(vim.fn.maparg('<leader>nb', 'n') ~= '')
assert(vim.fn.maparg('<leader>nd', 'n') ~= '')

vim.cmd('Obsidian new Привет мир')
local new_path = vault .. '/base/Привет мир.md'
assert(vim.fn.filereadable(new_path) == 1, 'ordinary note path keeps title')
local new_text = table.concat(vim.fn.readfile(new_path), '\n')
assert(new_text:find('Tags and associations: ', 1, true), 'base template inserted')
assert(not new_text:find('aliases:', 1, true), 'plugin frontmatter absent')

vim.cmd('Obsidian today')
local daily_path = vault .. '/daily/' .. os.date('%Y-%m-%d') .. '.md'
assert(vim.fn.filereadable(daily_path) == 1, 'today daily path')
local daily_text = table.concat(vim.fn.readfile(daily_path), '\n')
assert(daily_text:find('Tags and associations: [[daily]]', 1, true), 'daily template inserted')
vim.wait(200)

vim.cmd.edit(second)
notes.open_adjacent_daily(-1)
assert(vim.api.nvim_buf_get_name(0) == first, 'previous mapping opens existing note')

vim.cmd.edit(vim.fn.fnameescape(vault .. '/base/exercise list.md'))
assert(vim.api.nvim_buf_get_name(0) == vault .. '/base/exercise list.md', 'opened backlink source')
assert(vim.wait(3000, function() return #vim.lsp.get_clients({ bufnr = 0 }) > 0 end, 20),
    'Obsidian LSP attaches to vault markdown')
vim.api.nvim_win_set_cursor(0, { 1, 26 })
assert(require('obsidian.api').cursor_link(), 'cursor sees wiki link')
vim.cmd('Obsidian follow_link')
assert(vim.wait(3000, function()
    return vim.api.nvim_buf_get_name(0) == vault .. '/z-tags/exercise.md'
end, 20), 'wiki link opens tag note')
vim.cmd('Obsidian backlinks')
local picker
assert(vim.wait(3000, function()
    local state = require('telescope.actions.state')
    local ok, active = pcall(state.get_current_picker, vim.api.nvim_get_current_buf())
    picker = ok and active or nil
    return picker and picker.manager and picker.manager:num_results() == 2
end, 20), 'backlinks picker has referring notes')
assert(picker:get_selection().obsidian_item.filename:find('exercise list.md', 1, true),
    'tag backlink points to note')
require('telescope.actions').close(vim.api.nvim_get_current_buf())

print('PASS: notes paths, templates, mappings, daily navigation and tag backlinks')
vim.cmd('qa!')
