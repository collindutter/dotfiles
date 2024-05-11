return {
  -- Better session management
  'folke/persistence.nvim',
  event = 'BufReadPre',
  opts = {},
  init = function()
    local map = require('helpers.keys').map

    map('n', '<leader>sl', function()
      require('persistence').load { last = true }
    end, 'Load [s]ession [l]ast')
  end,
}
