return {
  -- Indentation guides
  'lukas-reineke/indent-blankline.nvim',
  main = 'ibl',
  opts = {
    exclude = {
      filetypes = {
        'help',
        'alpha',
        'dashboard',
        'neo-tree',
        'Trouble',
        'lazy',
        'mason',
        'toggleterm',
        'lazyterm',
      },
    },
  },
}
