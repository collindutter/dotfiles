return {
  {
    '<leader>m',
    mode = 'n',
    function()
      require('zen-mode').toggle {}
    end,
    desc = 'Toggle Zen Mode',
  },
}
