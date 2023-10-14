return {
  'stevearc/conform.nvim',
  opts = {
    formatters_by_ft = {
      python = { 'black' },
      lua = { 'stylua' },
    },
  },
  keys = {
    {
      '<leader>lf',
      function()
        require('conform').format { async = true, lsp_fallback = false }
      end,
      desc = 'Format buffer',
    },
  },
}
