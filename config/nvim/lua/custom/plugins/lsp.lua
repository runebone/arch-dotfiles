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
            { name = 'nvim_lsp' },
            { name = 'nvim_lua' },
            { name = 'luasnip' }, -- For luasnip users.
            { name = 'path' },
        }, {
            { name = 'buffer' },
        })
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
    local lsp_attach = function(_, bufnr)
        local opts = { buffer = bufnr }

        vim.keymap.set('n', '<F4>', vim.cmd.ClangdSwitchSourceHeader)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
        vim.keymap.set('n', 'go', vim.lsp.buf.type_definition, opts)
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
        vim.keymap.set('n', '<leader>k', vim.lsp.buf.signature_help, opts)
        vim.keymap.set('i', '<C-l>', vim.lsp.buf.completion, opts)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
        vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
        vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
        vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
        vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
        vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)

        vim.keymap.set('n', '<leader>f', vim.lsp.buf.code_action, opts)
    end

    local config = {
        on_attach = lsp_attach,
        capabilities = lsp_capabilities
    }

    local lspconfig = require('lspconfig')

    lspconfig.clangd.setup(config)
    lspconfig.gopls.setup(config)

    -- Python: use Pyright to go to definitions and Ruff for everything else
    lspconfig.ruff.setup(config)
    lspconfig.ruff_lsp.setup({
        on_attach = function(client, bufnr)
            config.on_attach(client, bufnr)
            if client.name == 'ruff_lsp' then
                -- Disable hover in favor of Pyright
                client.server_capabilities.hoverProvider = false
            end
        end,
        capabilities = config.capabilities
    })
    lspconfig.pyright.setup({
        on_attach = config.on_attach,
        capabilities = config.capabilities,
        settings = {
            pyright = {
                -- Using Ruff's import organizer
                disableOrganizeImports = true,
            },
            python = {
                analysis = {
                    -- Ignore all files for analysis to exclusively use Ruff for linting
                    ignore = { '*' },
                },
            },
        }
    })

    lspconfig.lua_ls.setup({
        on_attach = config.on_attach,
        capabilities = config.capabilities,
        settings = {
            Lua = {
                diagnostics = {
                    globals = { "vim" }
                }
            }
        }
    })
    lspconfig.bashls.setup(config)
    lspconfig.texlab.setup(config)
end

return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/nvim-cmp",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
        "rafamadriz/friendly-snippets",
        "j-hui/fidget.nvim",
    },
    config = setup
}
