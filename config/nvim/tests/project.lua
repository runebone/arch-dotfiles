local env = dofile(os.getenv('NVIM_TEST_ROOT') .. '/tests/bootstrap.lua')
local root = env.temporary .. '/project'
vim.fn.mkdir(root .. '/src/deep', 'p')
vim.fn.mkdir(root .. '/.git', 'p')
vim.fn.writefile({'needle'}, root .. '/top.go')
vim.fn.writefile({'needle'}, root .. '/src/deep/current.go')
vim.cmd.edit(root .. '/src/deep/current.go')
vim.api.nvim_set_current_dir(root .. '/src/deep')
local project = require('config.telescope.project')
assert(project.root() == root)
local function check_picker()
    local state = require('telescope.actions.state')
    local picker = state.get_current_picker(vim.api.nvim_get_current_buf())
    assert(picker.cwd == root)
    assert(picker.prompt_title:find(root, 1, true))
    assert(vim.wait(3000, function() return picker.manager and picker.manager:num_results() == 2 and picker:get_selection() end, 20))
    require('telescope.actions').close(vim.api.nvim_get_current_buf())
end
require('custom.plugins.telescope').config()
vim.fn.maparg('<C-p>', 'n', false, true).callback()
check_picker()
require('config.telescope.word_files').run({text='needle'})
check_picker()
local outside = env.temporary .. '/outside'
vim.fn.mkdir(outside, 'p')
vim.api.nvim_set_current_dir(outside)
assert(project.root() == root, 'buffer project should win over cwd')
vim.cmd.enew()
assert(project.root() == (vim.fs.root(outside, '.git') or outside), 'scratch uses cwd project')
local fs_root = vim.fs.root
vim.fs.root = function() return nil end
assert(project.root() == outside, 'non-Git cwd fallback')
vim.fs.root = fs_root

local worktree = env.temporary .. '/worktree'
vim.fn.mkdir(worktree .. '/sub', 'p')
vim.fn.writefile({'gitdir: /unused/worktree/metadata'}, worktree .. '/.git')
vim.api.nvim_set_current_dir(worktree .. '/sub')
assert(project.root() == worktree, 'worktree .git file')
assert(project.options('Explicit', {cwd=outside}).cwd == outside)
print('PASS: project scope, buffer/cwd fallback, worktree marker, picker titles and cross-directory results')
vim.cmd('qa!')
