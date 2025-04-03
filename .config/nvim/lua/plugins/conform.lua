return {
  -- Formatter
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  opts = {
    notify_on_error = false,
    formatters_by_ft = {
      python = { 'ruff_fix', 'ruff_format' },
      lua = { 'stylua' },
      typescript = { 'prettier' },
      json = { 'jq' },
      htmldjango = { 'prettier' },
      toml = { 'taplo' },
      bash = { 'shfmt' },
      sh = { 'shfmt' },
    },
    format_on_save = {
      timeout_ms = 500,
      lsp_format = 'fallback',
    },
  },
  keys = {
    {
      '<leader>cf',
      function()
        require('conform').format()
      end,
      desc = '[c]ode [f]ormat',
    },
  },
}
