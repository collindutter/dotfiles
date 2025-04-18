return {
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'williamboman/mason-lspconfig.nvim',
    },
    config = function()
      local hacks = require 'core.hacks'

      -- Set up LSP-specific keymaps
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
          vim.keymap.set({ 'n' }, '<leader>cd', vim.diagnostic.open_float, { buffer = event.buf, desc = '[c]ode [d]iagnostic' })

          vim.keymap.set({ 'n' }, '<leader>lr', function()
            vim.cmd 'LspRestart'
          end, { buffer = event.buf, desc = '[l]sp [r]estart' })
        end,
      })

      -- Make diagnostics pretty
      vim.diagnostic.config {
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
        },
      }

      -- Set up LSP servers installed by Mason
      require('mason-lspconfig').setup {
        ensure_installed = {},
        automatic_installation = false,
        handlers = {
          function(name)
            vim.lsp.enable(name)
          end,
        },
      }

      -- Set up file watcher that uses watchman
      if vim.fn.executable 'watchman' == 1 then
        require('vim.lsp._watchfiles')._watchfunc = hacks.watchfunc
      end
    end,
  },
}
