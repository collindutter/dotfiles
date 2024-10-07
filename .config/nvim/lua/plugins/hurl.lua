return {
  'jellydn/hurl.nvim',
  dependencies = {
    'MunifTanjim/nui.nvim',
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  ft = 'hurl',
  opts = {
    mode = 'popup',
  },
  init = function()
    local map = require('helpers.keys').map

    map('n', '<leader>an', function()
      vim.cmd 'HurlRunnerAt'
    end, '[a]pi [n]earest')

    map('n', '<leader>ac', function()
      vim.cmd 'HurlRunner'
    end, '[a]pi [c]urrent file')
  end,
}
