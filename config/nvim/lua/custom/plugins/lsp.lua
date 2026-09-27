local setup = function()
    -- ========== Completion (with luasnip backend) setup
    local cmp = require('cmp')
    local cmp_select = { behavior = cmp.SelectBehavior.Select }
    cmp.setup({
        snippet = {
            expand = function(args)
                require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
            end,
        },
        mapping = cmp.mapping.preset.insert({
            ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
            ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
            ['<C-y>'] = cmp.mapping.confirm({ select = true }),
            ["<C-Space>"] = cmp.mapping.complete(),
        }),
        sources = cmp.config.sources({
            { name = "nvim_lsp" },
            { name = "luasnip" },
            { name = "path" },
        }, {
            { name = "buffer" },
        })
    })

    -- ========== vim-dadbod-completion (buffer-local for sql)
    vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("SqlCompletion", { clear = true }),
        pattern = { "sql", "mysql", "plsql" },
        callback = function()
            cmp.setup.buffer({
                sources = cmp.config.sources({
                    { name = "vim-dadbod-completion" },
                    { name = "luasnip" },
                }, {
                    { name = "buffer" },
                }),
            })
        end,
    })

    -- ========== LuaSnip
    require("luasnip.loaders.from_vscode").lazy_load()
    require("luasnip.loaders.from_snipmate").lazy_load({paths = "~/.dotfiles/config/nvim/lua/custom/snippets"})

    local ls = require("luasnip")

    vim.keymap.set({"i"}, "<C-s>e", function() ls.expand() end, {silent = true})

    vim.keymap.set({"i", "s"}, "<C-s>;", function() ls.jump(1) end, {silent = true})
    vim.keymap.set({"i", "s"}, "<C-s>,", function() ls.jump(-1) end, {silent = true})

    vim.keymap.set({"i", "s"}, "<C-e>", function()
        if ls.choice_active() then
            ls.change_choice(1)
        end
    end, { silent = true })

    -- ========== LSPs setup
    require("fidget").setup({})

    require("mason").setup()
    require("mason-lspconfig").setup({
        ensure_installed = {
            "lua_ls",
            "gopls"
        }
    })

    local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()
    local lsp_attach = function(client, bufnr)
        local opts = { buffer = bufnr }

        if client.name == 'clangd' then
            vim.keymap.set('n', '<F4>', '<Cmd>LspClangdSwitchSourceHeader<CR>',
                { buffer = bufnr, desc = 'Switch C/C++ source and header' })
        end
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
        vim.keymap.set('n', 'go', vim.lsp.buf.type_definition, opts)
        vim.keymap.set('n', 'gi', function()
            require('telescope.builtin').lsp_implementations({ jump_type = 'never' })
        end, { buffer = bufnr, desc = 'Find implementations with Telescope' })
        vim.keymap.set('n', '<leader>ci', function()
            require('telescope.builtin').lsp_incoming_calls()
        end, { buffer = bufnr, desc = 'Incoming calls: who calls this function' })
        vim.keymap.set('n', '<leader>co', function()
            require('telescope.builtin').lsp_outgoing_calls()
        end, { buffer = bufnr, desc = 'Outgoing calls: functions called here' })
        vim.keymap.set('n', '<leader>cu', function()
            require('config.lsp.interface_usages').run()
        end, { buffer = bufnr, desc = 'Go: usages of all interface methods' })
        vim.keymap.set('n', 'gr', function()
            require('telescope.builtin').lsp_references({ jump_type = 'never' })
        end, { buffer = bufnr, desc = 'Find references with Telescope' })
        vim.keymap.set('n', '<leader>k', vim.lsp.buf.signature_help, opts)
        vim.keymap.set('i', '<C-l>', vim.lsp.buf.completion, opts)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
        vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
        vim.keymap.set('n', '<leader>ee', vim.diagnostic.open_float,
            { buffer = bufnr, desc = 'Show diagnostics at cursor' })
        vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
        vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
        vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)

        vim.keymap.set({ 'n', 'x' }, '<leader>ca', vim.lsp.buf.code_action,
            { buffer = bufnr, desc = 'Code actions and refactorings' })
    end

    vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('CustomLspMappings', { clear = true }),
        callback = function(event)
            local client = vim.lsp.get_client_by_id(event.data.client_id)
            if client then lsp_attach(client, event.buf) end
        end,
    })
    vim.lsp.config('*', { capabilities = lsp_capabilities })
    local format_group = vim.api.nvim_create_augroup('GoFormatOnSave', { clear = true })

    -- Настройка clangd
    vim.lsp.config.clangd = {}

    -- Настройка gopls
    vim.lsp.config.gopls = {
        settings = {
            gopls = {
                usePlaceholders = true,
                completeUnimported = true,
                buildFlags = {"-tags=unit,integration,e2e"},
                analyses = {
                    unusedparams = true,
                    -- modernize = false, -- interface{} -> any, etc.
                },
                staticcheck = true,
                codelenses = {
                    generate = true,
                    gc_details = true,
                },
                gofumpt = true,
            }
        },
        on_attach = function(client, bufnr)
            vim.keymap.set('n', '<leader>oi', function()
                vim.lsp.buf.code_action({
                    context = { only = { 'source.organizeImports' }, diagnostics = {} },
                    apply = true,
                })
            end, { buffer = bufnr, desc = 'Go: organize imports' })

            vim.api.nvim_clear_autocmds({ group = format_group, buffer = bufnr })
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = format_group,
              buffer = bufnr,
              callback = function()
                vim.lsp.buf.format({ bufnr = bufnr, id = client.id, async = false })
              end,
            })
        end,
    }

    -- Настройка остальных серверов
    vim.lsp.config.ruff = {}
    vim.lsp.config.pyright = {}

    vim.lsp.config.lua_ls = {
        settings = {
            Lua = {
                diagnostics = {
                    globals = { "vim" }
                }
            }
        }
    }

    vim.lsp.config.bashls = {}
    vim.lsp.config.texlab = {}

    -- Автозапуск LSP серверов
    vim.lsp.enable({'clangd', 'gopls', 'ruff', 'pyright', 'lua_ls', 'bashls', 'texlab'})


end

return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/nvim-cmp",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
        "rafamadriz/friendly-snippets",
        "j-hui/fidget.nvim",
        "kristijanhusak/vim-dadbod-completion",
    },
    config = setup
}
