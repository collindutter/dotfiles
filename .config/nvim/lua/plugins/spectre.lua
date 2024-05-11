return {
  'nvim-pack/nvim-spectre',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  init = function()
    local map = require('helpers.keys').map

    map('n', '<leader>F', function()
      require('spectre').toggle()
    end, '[F]ind and replace')
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
