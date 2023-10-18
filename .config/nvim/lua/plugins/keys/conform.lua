return {
  {
    '<leader>cf',
    function()
      require('conform').format { async = true, lsp_fallback = false }
    end,
    desc = 'Code format',
  },
}
