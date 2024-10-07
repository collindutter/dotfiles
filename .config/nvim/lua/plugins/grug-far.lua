return {
  'MagicDuck/grug-far.nvim',
  init = function()
    local map = require('helpers.keys').map

    map('n', '<leader>cw', function()
      require('grug-far').grug_far()
    end, '[c]hange [w]ords')
  end,
  opts = {
    keymaps = {
      qflist = { n = '<ctrl>q' },
      close = false,
    },
  },
}
