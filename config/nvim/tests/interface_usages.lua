local env = dofile(os.getenv('NVIM_TEST_ROOT') .. '/tests/bootstrap.lua')
local root = env.temporary .. '/interfaces'
vim.fn.mkdir(root .. '/embedded', 'p')
vim.fn.writefile({'module example.test/interfaces', '', 'go 1.23'}, root .. '/go.mod')
vim.fn.writefile({'package embedded', 'type Extra interface { Third() }'}, root .. '/embedded/embedded.go')
vim.fn.writefile({
    'package example',
    'import "example.test/interfaces/embedded"',
    'type Candidate interface { Created() }',
    'type Cancel interface { Cancelled() }',
    'type Alias = Candidate',
    'type EventPublisher interface { Alias; Candidate; Cancel; embedded.Extra }',
    'type Domain struct { candidate Candidate; cancel Cancel; extra embedded.Extra }',
    'func use(d Domain) { d.candidate.Created(); d.cancel.Cancelled(); d.extra.Third() }',
    'func useOther(p Candidate) { p.Created() }',
}, root .. '/main.go')
vim.cmd.edit(root .. '/main.go')
vim.bo.filetype = 'go'
local gopls = vim.fn.exepath('gopls')
if gopls == '' then gopls = vim.fn.stdpath('data') .. '/mason/bin/gopls' end
assert(vim.fn.executable(gopls) == 1, 'Install gopls before running this integration test')
local id = assert(vim.lsp.start({name='gopls', cmd={gopls}, root_dir=root}))
assert(vim.wait(15000, function() local client=vim.lsp.get_client_by_id(id); return client and client.initialized end, 50))
vim.api.nvim_win_set_cursor(0, {6, 6})
require('config.lsp.interface_usages').run()
local picker
assert(vim.wait(35000, function()
    if vim.bo.filetype == 'TelescopePrompt' then
        picker=require('telescope.actions.state').get_current_picker(vim.api.nvim_get_current_buf())
        return picker and picker.manager and picker.manager:num_results() > 0
    end
end, 50), 'interface picker did not open')
assert(picker.manager:num_results()==4, 'four deduplicated semantic references expected')
for entry in picker.manager:iter() do assert(entry.lnum==8 or entry.lnum==9) end
vim.lsp.get_client_by_id(id):stop(true)
print('PASS: actual gopls references across local, duplicate, aliased and imported embeddings')
vim.cmd('qa!')
