return {
  {
    's',
    function()
      require('flash').jump()
    end,
    desc = 'Flash',
    mode = { 'n', 'x', 'o' },
  },
  {
    'S',
    function()
      require('flash').treesitter()
    end,
    desc = 'Flash Treesitter',
    mode = { 'n', 'x', 'o' },
  },
}
