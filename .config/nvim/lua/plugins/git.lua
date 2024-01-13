-- Plugins related to Git
return {
  {
    -- Adds git related signs to the gutter
    'lewis6991/gitsigns.nvim',
    init = function() end,
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },
}
