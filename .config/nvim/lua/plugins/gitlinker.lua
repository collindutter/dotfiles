return {
  'linrongbin16/gitlinker.nvim',
  opts = {},
  init = function()
    local map = require('helpers.keys').map

    map('n', '<leader>gl', require('gitlinker').link, '[g]it [l]ink')
    map('n', '<leader>gb', function()
      require('gitlinker').link { router_type = 'blame' }
    end, '[g]it [b]lame')
  end,
}
