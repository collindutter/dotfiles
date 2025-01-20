return {
  'linrongbin16/gitlinker.nvim',
  opts = {},
  keys = {
    {
      '<leader>gl',
      function()
        require('gitlinker').link()
      end,
      mode = { 'n', 'v' },
      desc = '[g]it [l]ink',
    },
    {
      '<leader>gb',
      function()
        require('gitlinker').link { router_type = 'blame' }
      end,
      mode = { 'n', 'v' },
      desc = '[g]it [b]lame',
    },
  },
}
