return {
  'rgroli/other.nvim',
  main = 'other-nvim',
  opts = {
    mappings = {
      'python',
    },
    style = {
      border = 'rounded',
    },
  },
  keys = {
    {
      '<leader>o',
      '<cmd>Other<cr>',
      desc = '[o]ther file',
    },
  },
}
