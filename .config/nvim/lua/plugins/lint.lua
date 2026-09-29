return {
  -- Linter
  'mfussenegger/nvim-lint',
  config = function(_)
    local lint = require 'lint'
    local luacheck = require('lint').linters.luacheck

    luacheck.args = {
      '--formatter',
      'plain',
      '--codes',
      '--ranges',
      '--globals',
      'vim',
      '-',
    }

    lint.linters_by_ft = {
      lua = { 'luacheck' },
    }

    vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
      callback = function(event)
        local linters = lint.linters_by_ft[vim.bo[event.buf].filetype]
        if linters and #linters > 0 then
          lint.try_lint()
        end
      end,
    })
  end,
}
