return {
  -- Test runner
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'antoinemadec/FixCursorHold.nvim',
    'nvim-treesitter/nvim-treesitter',
    -- Adapters
    'nvim-neotest/neotest-python',
  },
  init = function()
    local map = require('helpers.keys').map

    map('n', '<leader>tc', function()
      require('neotest').run.run(vim.fn.expand '%')
    end, '[t]est [c]urrent file')

    map('n', '<leader>tn', function()
      require('neotest').run.run()
    end, '[t]est [n]earest')

    map('n', '<leader>td', function()
      require('neotest').run.run {
        suite = false,
        strategy = 'dap',
      }
    end, '[t]est [d]ebug')

    map('n', '<leader>dt', function()
      require('neotest').run.run {
        suite = false,
        strategy = 'dap',
      }
    end, '[t]est [d]ebug')

    map('n', '<leader>ts', function()
      require('neotest').run.stop()
    end, '[t]est [s]top')

    map('n', '<leader>tu', function()
      require('neotest').output_panel.toggle()
    end, '[t]est [u]I')
  end,
  opts = function()
    return {
      adapters = {
        require 'neotest-python' {
          dap = { justMyCode = false },
          args = { '-vv' },
        },
      },
    }
  end,
}
