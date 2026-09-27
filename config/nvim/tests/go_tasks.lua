local env = dofile(os.getenv('NVIM_TEST_ROOT') .. '/tests/bootstrap.lua')
local root = env.temporary .. '/tasks'
vim.fn.mkdir(root .. '/calc', 'p')
vim.fn.writefile({'module example.test/tasks', '', 'go 1.23'}, root .. '/go.mod')
local file = root .. '/calc/calc_test.go'
local lines = {
    'package calc',
    'import "testing"',
    'func TestOne(t *testing.T) {',
    '    t.Error("expected fixture failure")',
    '}',
    'func TestOther(t *testing.T) {}',
}
vim.fn.writefile(lines, file)
vim.cmd.edit(file)
vim.bo.filetype = 'go'
vim.treesitter.get_parser(0, 'go'):parse()
vim.api.nvim_win_set_cursor(0, {4, 5})
local source = vim.api.nvim_get_current_buf()
local messages = {}
vim.notify = function(message) messages[#messages + 1] = message end
local tasks = require('config.go_tasks')
local function finished(count)
    assert(vim.wait(60000, function() return #messages >= count end, 50), 'Go task timed out')
    vim.cmd.stopinsert()
end
-- A real failing Go test must produce an actionable location.
tasks.test_nearest()
finished(1)
local qf = vim.fn.getqflist({items=0,title=0})
assert(qf.title:find('^TestOne$',1,true), 'nearest test selection')
assert(#qf.items > 0, 'missing test failure location')
assert(vim.api.nvim_buf_get_name(qf.items[1].bufnr)==file, 'wrong failure file')
assert(qf.items[1].lnum==4, 'wrong failure line')
assert(messages[1]:find('exited with 1',1,true))
-- Rerun from the terminal, after fixing the fixture on disk.
lines[4]='    t.Log("pass")'; vim.fn.writefile(lines,file)
tasks.rerun(); finished(2)
assert(messages[2]:find('passed',1,true))
assert(#vim.fn.getqflist()==0, 'stale failure locations')
vim.api.nvim_set_current_buf(source)
vim.cmd('edit!')
tasks.test_package(); finished(3)
assert(messages[3]:find('passed',1,true))
assert(not vim.fn.getqflist({title=0}).title:find('-run',1,true))
vim.fn.mkdir(root .. '/cmd/demo', 'p')
vim.fn.writefile({'package main', 'func main() { helper() }'}, root .. '/cmd/demo/main.go')
vim.fn.writefile({'package main', 'func helper() {}'}, root .. '/cmd/demo/helper.go')
vim.cmd.edit(root .. '/cmd/demo/main.go')
vim.bo.filetype = 'go'
tasks.run_package(); finished(4)
assert(messages[4]:find('passed', 1, true), 'multi-file main package failed')
assert(vim.fn.getqflist({title=0}).title:find('go run ./cmd/demo', 1, true))
local parsed=tasks.diagnostics({'calc/calc_test.go:4:2: compile issue'},root..'/calc',root)
assert(parsed[1].filename==file and parsed[1].col==2)
print('PASS: real nearest/package tests, multi-file package run, failure locations, terminal rerun and clearing stale failures')
vim.cmd('qa!')
