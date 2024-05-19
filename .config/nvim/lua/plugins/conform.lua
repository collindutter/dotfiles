return {
  -- Formatter
  'stevearc/conform.nvim',
  opts = {
    formatters_by_ft = {
      python = { 'ruff_fix', 'ruff_format' },
      lua = { 'stylua' },
      sh = { 'shfmt' },
      typescript = { 'prettier' },
    },
    yamlfix = {
      -- Change where to find the command
      command = 'local/path/yamlfix',
      -- Adds environment args to the yamlfix formatter
      env = {
        YAMLFIX_SEQUENCE_STYLE = 'block_style',
      },
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
