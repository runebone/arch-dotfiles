local M = {}
local last_directory = {}

function M.run()
    local cwd = vim.fn.getcwd()
    vim.ui.input({
        prompt = 'Search directory (includes ignored files): ',
        default = last_directory[cwd] or '',
        completion = 'dir',
    }, function(input)
        if not input or input == '' then return end
        local directory = vim.fn.expand(input)
        if not vim.startswith(directory, '/') then
            directory = vim.fs.joinpath(cwd, directory)
        end
        directory = vim.fs.normalize(directory)
        if vim.fn.isdirectory(directory) == 0 then
            vim.notify('Directory does not exist: ' .. directory, vim.log.levels.WARN)
            return
        end
        last_directory[cwd] = input
        require('telescope.builtin').live_grep({
            cwd = directory,
            search_dirs = { '.' },
            prompt_title = require('config.telescope.project').title('Search (includes ignored files)', directory),
            additional_args = { '--no-ignore' },
        })
    end)
end

return M
