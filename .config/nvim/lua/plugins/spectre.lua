return {
  -- Find and replace
  'nvim-pack/nvim-spectre',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  init = function()
    local map = require('helpers.keys').map

    map('n', '<leader>cW', function()
      require('spectre').toggle()
    end, '[c]hange and [W]ords')
  end,
  opts = {
    mapping = {
      ['send_to_qf'] = {
        map = '<C-q>',
        cmd = "<cmd>lua require('spectre.actions').send_to_qf()<cr>",
        desc = 'Send all items to quickfix',
      },
    },
  },
}
