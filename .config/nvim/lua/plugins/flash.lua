return {
  'folke/flash.nvim',
  opts = function()
    local map = require('helpers.keys').map

    map({ 'n', 'x', 'o' }, 's', function()
      require('flash').jump()
    end, 'Flash')
    map({ 'n', 'x', 'o' }, 'S', function()
      require('flash').treesitter()
    end, 'Flash Treesitter')
  end,
}
