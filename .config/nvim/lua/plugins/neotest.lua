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
  keys = {
    {
      '<leader>tc',
      function()
        require('neotest').run.run(vim.fn.expand '%')
      end,
      desc = '[t]est [c]urrent file',
    },
    {
      '<leader>tn',
      function()
        require('neotest').run.run()
      end,
      desc = '[t]est [n]earest',
    },
    {
      '<leader>ts',
      function()
        require('neotest').run.stop()
      end,
      desc = '[t]est [s]top',
    },
    {
      '<leader>tu',
      function()
        require('neotest').output_panel.toggle()
      end,
      desc = '[t]est [u]I',
    },
  },
  opts = function()
    return {
      adapters = {
        require 'neotest-python' {
          args = { '-vv' },
        },
      },
    }
  end,
}
