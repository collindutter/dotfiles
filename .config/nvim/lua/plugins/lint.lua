return {
  -- Linter
  'mfussenegger/nvim-lint',
  config = function(_)
    local lint = require 'lint'

    lint.linters_by_ft = {
      python = { 'ruff' },
      lua = { 'luacheck' },
      typescriptreact = { 'eslint' },
      typescript = { 'eslint' },
      javascript = { 'eslint' },
      javascriptreact = { 'eslint' },
    }

    vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
      callback = function()
        require('lint').try_lint()
      end,
    })
  end,
}
