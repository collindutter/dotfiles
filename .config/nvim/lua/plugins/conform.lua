return {
  -- Formatter
  'stevearc/conform.nvim',
  opts = {
    notify_on_error = false,
    formatters_by_ft = {
      python = { 'ruff_fix', 'ruff_format' },
      lua = { 'stylua' },
      typescript = { 'prettier' },
      json = { 'jq' },
    },
    format_on_save = {
      timeout_ms = 500,
      lsp_format = 'fallback',
    },
  },
  init = function()
    local map = require('helpers.keys').map

    map('n', '<leader>cf', function()
      require('conform').format()
    end, '[c]ode [f]ormat')
  end,
}
