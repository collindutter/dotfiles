return {
  -- Show pending keybinds
  'folke/which-key.nvim',
  opts = {
    preset = 'helix',
    win = {
      border = 'rounded',
    },
  },
  init = function()
    -- Document existing key chains
    require('which-key').add {
      { '<leader>c', group = 'Code', mode = { 'n', 'x' } },
      { '<leader>d', group = 'Debugger' },
      { '<leader>g', group = 'Git' },
      { '<leader>b', group = 'Buffers' },
      { '<leader>f', group = 'Find' },
      { '<leader>t', group = 'Test' },
      { '<leader>s', group = 'Session' },
      { '<leader>l', group = 'Lsp' },
    }
  end,
}
