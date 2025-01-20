return {
  {
    -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  {
    'neovim/nvim-lspconfig',
    opts = {
      diagnostic_config = {
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = '',
            [vim.diagnostic.severity.WARN] = '',
            [vim.diagnostic.severity.HINT] = '󰌵',
            [vim.diagnostic.severity.INFO] = '󰋼',
          },
        },
        severity_sort = true,
        float = {
          border = 'rounded',
        },
      },
      ui = {
        float = {
          border = 'rounded',
        },
      },
    },
    config = function(_, opts)
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
          local function lsp_map(lhs, rhs, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, lhs, rhs, { buffer = event.buf, desc = desc })
          end

          -- Actions
          lsp_map('<leader>cr', vim.lsp.buf.rename, '[c]ode [r]ename')
          lsp_map('<leader>ca', vim.lsp.buf.code_action, '[c]ode [a]ction', { 'n', 'x' })

          -- Diagnostics
          lsp_map('<leader>cd', vim.diagnostic.open_float, '[c]ode [d]iagnostic')

          -- Go-Tos
          lsp_map('gd', vim.lsp.buf.definition, '[g]oto [d]efinition')
          lsp_map('gD', vim.lsp.buf.declaration, '[g]oto [D]eclartion')

          lsp_map('<leader>lr', function()
            vim.cmd 'LspRestart'
          end, '[l]sp [r]estart')
        end,
      })

      -- Make diagnostics pretty
      vim.diagnostic.config(opts.diagnostic_config)
      -- Hover configuration
      vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, opts.ui.float)
      -- Signature help configuration
      vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, opts.ui.float)

      -- Add border to :LspInfo
      require('lspconfig.ui.windows').default_options.border = 'rounded'
    end,
  },
}
