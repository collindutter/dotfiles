return {
  -- Better session management
  'folke/persistence.nvim',
  event = 'BufReadPre',
  opts = {},
  keys = {
    {
      '<leader>ql',
      function()
        require('persistence').load { last = true }
      end,
      desc = 'Load [l]ast session',
    },
  },
}
