return {
  'folke/flash.nvim',
  event = 'VeryLazy',
  keys = {
    {
      's',
      function()
        require('flash').jump()
      end,
      mode = { 'n', 'x', 'o' },
      desc = 'Flash',
    },
    {
      'S',
      function()
        require('flash').treesitter()
      end,
      mode = { 'n', 'x', 'o' },
      desc = 'Flash Treesitter',
    },
  },
}
