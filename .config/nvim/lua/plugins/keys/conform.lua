return {
  {
    '<leader>lf',
    function()
      require('conform').format { async = true, lsp_fallback = false }
    end,
  desc = 'Format buffer',
  },
}
