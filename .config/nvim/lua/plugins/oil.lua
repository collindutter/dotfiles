return {
  'stevearc/oil.nvim',
  opts = {
    keymaps = {
      ['<C-l>'] = false,
      ['<C-h>'] = false,
      ['q'] = 'actions.close',
      ['H'] = 'actions.toggle_hidden',
    },
  },
  keys = {
    {
      '-',
      '<cmd>Oil<cr>',
      desc = 'Open Oil',
    },
  },
}
