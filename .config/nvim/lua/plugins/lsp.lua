-- Plugins that integrate with the LSP
return {
  {
    'pmizio/typescript-tools.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Install LSPs to stdpath for neovim
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',

      -- Additional lua configuration
      'folke/neodev.nvim',
      'j-hui/fidget.nvim',
    },
    opts = {
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
      mason_ensure_installed = {
        'stylua',
        'luacheck',
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
      mason_lspconfig_ensure_installed = {
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
      local on_attach = function(_, bufnr)
        local lsp_map = require('helpers.keys').lsp_map

        -- Actions
        lsp_map('<leader>cr', vim.lsp.buf.rename, bufnr, '[c]ode [r]ename')
        lsp_map('<leader>ca', vim.lsp.buf.code_action, bufnr, '[c]ode [a]ction')

        -- Diagnostics
        lsp_map('<leader>cd', vim.diagnostic.open_float, bufnr, '[c]ode [d]iagnostic')
        lsp_map('[d', vim.diagnostic.goto_prev, bufnr, 'Goto previous [d]iagnostic message')
        lsp_map(']d', vim.diagnostic.goto_next, bufnr, 'Goto next [d]iagnostic message')

        lsp_map('gd', vim.lsp.buf.definition, bufnr, '[g]oto [d]efinition')
        lsp_map('gD', vim.lsp.buf.declaration, bufnr, '[g]oto [D]eclartion')
        lsp_map('gr', require('telescope.builtin').lsp_references, bufnr, '[g]oto [r]eferences')
        lsp_map('gI', require('telescope.builtin').lsp_implementations, bufnr, '[g]oto [i]mplementation')

        -- See `:help K` for why this keymap
        lsp_map('K', vim.lsp.buf.hover, bufnr, 'Hover documentation')
        vim.keymap.set('i', '<c-k>', vim.lsp.buf.signature_help, { silent = true, buffer = bufnr, desc = 'Signature help' })
      end

      -- mason-lspconfig requires that these setup functions are called in this order
      -- before setting up the servers.
      require('mason').setup()
      local mason_lspconfig = require 'mason-lspconfig'

      local lsp_servers = opts.mason_lspconfig_ensure_installed
      mason_lspconfig.setup {
        ensure_installed = vim.tbl_keys(lsp_servers),
      }

      -- Setup neovim lua configuration
      require('neodev').setup()

      -- nvim-cmp supports additional completion capabilities, so broadcast that to servers
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

      -- Create a user command for installing all the servers
      vim.api.nvim_create_user_command('MasonInstallAll', function()
        vim.cmd('MasonInstall ' .. table.concat(opts.mason_ensure_installed, ' '))
      end, {})

      -- Define pretty signs
      for type, icon in pairs(opts.signs) do
        vim.fn.sign_define(type, { text = icon, texthl = type, numhl = type })
      end

      -- Make diagnostics pretty
      vim.diagnostic.config(opts.diagnostic_config)
      -- Hover configuration
      vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, opts.float)

      -- Signature help configuration
      vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, opts.float)

      -- Add border to :LspInfo
      require('lspconfig.ui.windows').default_options.border = 'rounded'

      -- Ensure the servers above are installed
      mason_lspconfig.setup_handlers {
        function(server_name)
          require('lspconfig')[server_name].setup {
            capabilities = capabilities,
            on_attach = on_attach,
            settings = lsp_servers[server_name],
          }
        end,
        ['tsserver'] = function()
          require('typescript-tools').setup {
            on_attach = on_attach,
            settings = lsp_servers['tsserver'],
          }
        end,
      }
    end,
  },
}
