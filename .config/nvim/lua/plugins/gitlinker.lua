return {
  'linrongbin16/gitlinker.nvim',
  opts = {},
  init = function()
    local map = require('helpers.keys').map

    map({ 'n', 'v' }, '<leader>gl', require('gitlinker').link, '[g]it [l]ink')
    map({ 'n', 'v' }, '<leader>gb', function()
      require('gitlinker').link { router_type = 'blame' }
    end, '[g]it [b]lame')
  end,
}
