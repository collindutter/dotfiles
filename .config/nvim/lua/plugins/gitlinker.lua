return {
  -- Link to the current line on GitHub
  'ruifm/gitlinker.nvim',
  requires = 'nvim-lua/plenary.nvim',
  opts = {
    mappings = nil,
  },
  init = function()
    local map = require('helpers.keys').map

    map('n', '<leader>gy', function()
      require('gitlinker').get_repo_url()
    end, '[g]it line [y]ank')
  end,
}
