dofile(os.getenv('NVIM_TEST_ROOT') .. '/tests/bootstrap.lua')
local dir=vim.fn.tempname(); vim.fn.mkdir(dir,'p')
local files={}
for i=1,600 do
 local name=string.rep('a',100)..i..'.go'
 files[i]=name
 vim.fn.writefile({'needle', 'other'},dir..'/'..name)
end
vim.fn.writefile({'needle'},dir..'/outside.go')
local calls=0
local finders=require('telescope.finders')
local original=finders.new_async_job
finders.new_async_job=function(opts)
 local generator=opts.command_generator
 opts.command_generator=function(prompt)
  local args=generator(prompt)
  calls=calls+1
  local size=0
  for _,arg in ipairs(args) do size=size+#arg+9; assert(arg~='.', 'whole directory scan') end
  assert(size<50000,'batch too large')
  return args
 end
 return original(opts)
end
local conf=require('telescope.config').values
require('telescope.pickers').new({cwd=dir},{finder=require('config.telescope.scoped_grep').new({cwd=dir,files=files,pattern=function(s) return s end,entry_maker=require('telescope.make_entry').gen_from_vimgrep({cwd=dir})}),sorter=require('telescope.sorters').empty()}):find()
local state=require('telescope.actions.state')
local p=state.get_current_picker(vim.api.nvim_get_current_buf())
p:set_prompt('needle')
assert(vim.wait(5000,function() return p.manager and p.manager:num_results()==600 and p:get_selection() end,20),'batched results')
assert(calls>=2,'expected several batches')
for e in p.manager:iter() do assert(not e.filename:find('outside',1,true)) end
p:set_prompt('no_match')
p:set_prompt('other')
assert(vim.wait(5000,function() return p.manager and p.manager:num_results()==600 and p:get_selection() and p:get_selection().lnum==2 end,20),'replacement search')
require('telescope.actions').close(vim.api.nvim_get_current_buf())
finders.new_async_job=original
local small=vim.fn.tempname(); vim.fn.mkdir(small,'p');vim.fn.writefile({'Router'},small..'/alpha.go')
require('config.telescope.path_text').run({cwd=small,path_query='alp'})
local function ready()
 local picker
 assert(vim.wait(3000,function()
  picker=state.get_current_picker(vim.api.nvim_get_current_buf())
  return picker and picker.manager and picker.manager:num_results()==1 and picker:get_selection()
 end,20))
 return picker
end
ready(); require('telescope.actions').select_default(vim.api.nvim_get_current_buf())
p=state.get_current_picker(vim.api.nvim_get_current_buf());p:set_prompt('rtr');ready()
vim.fn.maparg('<C-b>','i',false,true).callback()
ready();assert(state.get_current_line()=='alp')
require('telescope.actions').select_default(vim.api.nvim_get_current_buf())
ready();assert(state.get_current_line()=='rtr','text query lost')
print('PASS: 600-file batched search, scope, query replacement, preserved path/text queries')
vim.cmd('qa!')
