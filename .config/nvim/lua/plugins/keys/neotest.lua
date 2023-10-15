return {
  {
    '<leader>tc',
    function()
      require('neotest').run.run(vim.fn.expand '%')
    end,
    desc = 'Run the current file',
  },
  {
    '<leader>td',
    function()
      require('neotest').run.run {
        suite = false,
        strategy = 'dap',
      }
    end,
    desc = 'Debug the nearest test',
  },
  {
    '<leader>dt',
    function()
      require('neotest').run.run {
        suite = false,
        strategy = 'dap',
      }
    end,
    desc = 'Debug the nearest test',
  },
  {
    '<leader>ts',
    function()
      require('neotest').run.stop()
    end,
    desc = 'Stop the nearest test',
  },
}
