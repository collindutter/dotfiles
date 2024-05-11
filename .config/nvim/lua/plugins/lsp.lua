return {
  'neovim/nvim-lspconfig',
  dependencies = {
    -- Install LSPs to stdpath for neovim
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',

    -- Additional lua configuration
    { 'folke/neodev.nvim', opts = {} },
  },
  opts = {
    ui = {
      diagnostic_config = {
        virtual_text = true,
        update_in_insert = true,
        underline = true,
        severity_sort = true,
        float = {
          focusable = true,
          style = 'minimal',
          border = 'rounded',
        },
      },
      float = {
        focusable = true,
        style = 'minimal',
        border = 'rounded',
      },
      signs = {
        DiagnosticSignError = '',
        DiagnosticSignWarn = '',
        DiagnosticSignHint = '󰌵',
        DiagnosticInfo = '󰋼',
        DapBreakpoint = '',
        DapBreakpointCondition = '',
        DapBreakpointRejected = '',
        DapLogPoint = '.>',
        DapStopped = '󰁕',
      },
    },
    servers = {
      ruff_lsp = {},
      jsonls = {},
      pyright = {},
      tsserver = {},
      html = {},
      yamlls = {
        yaml = {
          customTags = {
            '!And scalar',
            '!And mapping',
            '!And sequence',
            '!If scalar',
            '!If mapping',
            '!If sequence',
            '!Not scalar',
            '!Not mapping',
            '!Not sequence',
            '!Equals scalar',
            '!Equals mapping',
            '!Equals sequence',
            '!Or scalar',
            '!Or mapping',
            '!Or sequence',
            '!FindInMap scalar',
            '!FindInMap mapping',
            '!FindInMap sequence',
            '!Base64 scalar',
            '!Base64 mapping',
            '!Base64 sequence',
            '!Cidr scalar',
            '!Cidr mapping',
            '!Cidr sequence',
            '!Ref scalar',
            '!Ref mapping',
            '!Ref sequence',
            '!Sub scalar',
            '!Sub mapping',
            '!Sub sequence',
            '!GetAtt scalar',
            '!GetAtt mapping',
            '!GetAtt sequence',
            '!GetAZs scalar',
            '!GetAZs mapping',
            '!GetAZs sequence',
            '!ImportValue scalar',
            '!ImportValue mapping',
            '!ImportValue sequence',
            '!Select scalar',
            '!Select mapping',
            '!Select sequence',
            '!Split scalar',
            '!Split mapping',
            '!Split sequence',
            '!Join scalar',
            '!Join mapping',
            '!Join sequence',
          },
        },
      },
      lua_ls = {
        Lua = {
          completion = {
            callSnippet = 'Replace',
          },
          workspace = {
            checkThirdParty = false,
            library = {
              [vim.fn.expand '$VIMRUNTIME/lua'] = true,
              [vim.fn.stdpath 'config' .. '/lua'] = true,
            },
          },
        },
      },
    },
  },
  config = function(_, opts)
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
      callback = function(event)
        local function lsp_map(lhs, rhs, desc)
          vim.keymap.set('n', lhs, rhs, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        -- Actions
        lsp_map('<leader>rn', vim.lsp.buf.rename, '[r]e[n]ame')
        lsp_map('<leader>ca', vim.lsp.buf.code_action, '[c]ode [a]ction')

        -- Diagnostics
        lsp_map('<leader>cd', vim.diagnostic.open_float, '[c]ode [d]iagnostic')
        lsp_map('[d', vim.diagnostic.goto_prev, 'Goto previous [d]iagnostic message')
        lsp_map(']d', vim.diagnostic.goto_next, 'Goto next [d]iagnostic message')

        lsp_map('gd', vim.lsp.buf.definition, '[g]oto [d]efinition')
        lsp_map('gD', vim.lsp.buf.declaration, '[g]oto [D]eclartion')
        lsp_map('gr', require('fzf-lua').lsp_references, '[g]oto [r]eferences')
        lsp_map('gI', require('fzf-lua').lsp_implementations, '[g]oto [i]mplementation')

        lsp_map('<leader>lr', function()
          vim.cmd 'LspRestart'
        end, '[l]sp [r]estart')

        -- See `:help K` for why this keymap
        lsp_map('K', vim.lsp.buf.hover, 'Hover documentation')
      end,
    })

    -- LSP servers and clients are able to communicate to each other what features they support.
    --  By default, Neovim doesn't support everything that is in the LSP specification.
    --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
    --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

    -- Define pretty signs
    for type, icon in pairs(opts.ui.signs) do
      vim.fn.sign_define(type, { text = icon, texthl = type, numhl = type })
    end

    -- Make diagnostics pretty
    vim.diagnostic.config(opts.ui.diagnostic_config)
    -- Hover configuration
    vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, opts.ui.float)

    -- Signature help configuration
    vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, opts.ui.float)

    -- Add border to :LspInfo
    require('lspconfig.ui.windows').default_options.border = 'rounded'

    -- Ensure the servers and tools above are installed
    require('mason').setup()

    local ensure_installed = vim.tbl_keys(opts.servers or {})
    require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    require('mason-lspconfig').setup {
      handlers = {
        function(server_name)
          local server = opts.servers[server_name] or {}
          -- This handles overriding only values explicitly passed
          -- by the server configuration above. Useful when disabling
          -- certain features of an LSP (for example, turning off formatting for tsserver)
          server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
          require('lspconfig')[server_name].setup(server)
        end,
      },
    }
  end,
}
