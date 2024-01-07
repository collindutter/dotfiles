-- Plugins that provide formatting capabilities
return {
  {
    -- Formatter
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        python = { 'black' },
        lua = { 'stylua' },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    },
    init = function()
      local map = require('helpers.keys').map

      map('n', '<leader>cf', function()
        require('conform').format { async = true, lsp_fallback = false }
      end, 'Code format')
    end,
  },
}
