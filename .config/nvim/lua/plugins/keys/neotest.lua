return {
  {
    '<leader>tc',
    function()
      require('neotest').run.run(vim.fn.expand '%')
    end,
    desc = 'Test current file',
  },
  {
    '<leader>td',
    function()
      require('neotest').run.run {
        suite = false,
        strategy = 'dap',
      }
    end,
    desc = 'Test debug',
  },
  {
    '<leader>dt',
    function()
      require('neotest').run.run {
        suite = false,
        strategy = 'dap',
      }
    end,
    desc = 'Debug test',
  },
  {
    '<leader>ts',
    function()
      require('neotest').run.stop()
    end,
    desc = 'Test stop',
  },
}
