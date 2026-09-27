local env = dofile(os.getenv('NVIM_TEST_ROOT') .. '/tests/bootstrap.lua')
local directory = env.temporary .. '/source test | literal'
vim.fn.mkdir(directory, 'p')
local source, test = directory .. '/sample.go', directory .. '/sample_test.go'
vim.fn.writefile({'package sample'}, source)
vim.fn.writefile({'package sample_test'}, test)
vim.cmd.edit({ source })
vim.bo.filetype='go'
dofile(env.root .. '/after/ftplugin/go.lua')
local mapping=vim.fn.maparg(' ta','n',false,true)
assert(mapping.buffer==1)
mapping.callback()
assert(vim.api.nvim_buf_get_name(0)==test)
require('config.go').alternate()
assert(vim.api.nvim_buf_get_name(0)==source)
local missing=directory .. '/missing.go'
vim.cmd.edit({ missing })
local notification
vim.notify=function(message) notification=message end
require('config.go').alternate()
assert(vim.api.nvim_buf_get_name(0)==missing)
assert(notification:find('No matching file:',1,true))
assert(vim.fn.filereadable(directory .. '/missing_test.go')==0)
print('PASS: source/test roundtrip, buffer mapping, literal filenames and missing counterpart')
vim.cmd('qa!')
