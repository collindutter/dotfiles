return {
  -- Center buffer without noise
  'folke/zen-mode.nvim',
  opts = {},
  keys = {
    {
      '<leader>m',
      mode = 'n',
      function()
        require('zen-mode').toggle {}
      end,
      desc = 'Toggle Zen Mode',
    },
  },
}
