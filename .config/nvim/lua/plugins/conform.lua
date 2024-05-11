return {
  -- Formatter
  'stevearc/conform.nvim',
  opts = {
    formatters_by_ft = {
      python = { 'black' },
      lua = { 'stylua' },
      sh = { 'shfmt' },
      typescript = { 'prettier' },
    },
    -- These get passed to the formatter command
    format_on_save = {
      async = true,
      timeout_ms = 500,
      lsp_fallback = true,
      quiet = true,
    },
  },
  init = function()
    local map = require('helpers.keys').map

    map('n', '<leader>cf', function()
      require('conform').format()
    end, '[c]ode [f]ormat')
  end,
}
