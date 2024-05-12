return {
  -- Show pending keybinds
  'folke/which-key.nvim',
  event = 'VimEnter',
  opts = {
    window = {
      border = 'rounded',
    },
  },
  init = function()
    -- Document existing key chains
    require('which-key').register {
      ['<leader>c'] = { name = 'Code', _ = 'which_key_ignore' },
      ['<leader>d'] = { name = 'Debugger', _ = 'which_key_ignore' },
      ['<leader>g'] = { name = 'Git', _ = 'which_key_ignore' },
      ['<leader>b'] = { name = 'Buffers', _ = 'which_key_ignore' },
      ['<leader>f'] = { name = 'Find', _ = 'which_key_ignore' },
      ['<leader>t'] = { name = 'Test', _ = 'which_key_ignore' },
      ['<leader>s'] = { name = 'Session', _ = 'which_key_ignore' },
      ['<leader>l'] = { name = 'Lsp', _ = 'which_key_ignore' },
    }
  end,
}
