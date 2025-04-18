local hacks = require 'core.hacks'
-- Make diagnostics pretty
vim.diagnostic.config {
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '',
      [vim.diagnostic.severity.WARN] = '',
      [vim.diagnostic.severity.HINT] = '󰌵',
      [vim.diagnostic.severity.INFO] = '󰋼',
    },
  },
  severity_sort = true,
}

-- Set up file watcher that uses watchman
if vim.fn.executable 'watchman' == 1 then
  require('vim.lsp._watchfiles')._watchfunc = hacks.watchfunc
end
