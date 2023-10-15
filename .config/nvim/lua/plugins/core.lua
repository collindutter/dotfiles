return {
  {
    'famiu/bufdelete.nvim',
    version = '*',
    keys = {
      {
        '<leader>c',
        function()
          require('bufdelete').bufdelete(0, false)
        end,
        desc = 'Close buffer',
      },
      {
        '<leader>C',
        function()
          require('bufdelete').bufdelete(0, true)
        end,
        desc = 'Force close buffer',
      },
    },
  },
  {
    'mrjones2014/smart-splits.nvim',
    opts = {},
    keys = {
      -- resizing splits
      {
        '<C-Left>',
        mode = 'n',
        function()
          require('smart-splits').resize_left()
        end,
        desc = 'Resize left',
      },
      {
        '<C-Down>',
        mode = 'n',
        function()
          require('smart-splits').resize_down()
        end,
        desc = 'Resize down',
      },
      {
        '<C-Up>',
        mode = 'n',
        function()
          require('smart-splits').resize_up()
        end,
        desc = 'Resize up',
      },
      {
        '<C-Right>',
        mode = 'n',
        function()
          require('smart-splits').resize_right()
        end,
        desc = 'Resize right',
      },
      -- moving between splits
      {
        '<C-h>',
        mode = 'n',
        function()
          require('smart-splits').move_cursor_left()
        end,
        desc = 'Move cursor left',
      },
      {
        '<C-j>',
        mode = 'n',
        function()
          require('smart-splits').move_cursor_down()
        end,
        desc = 'Move cursor down',
      },
      {
        '<C-k>',
        mode = 'n',
        function()
          require('smart-splits').move_cursor_up()
        end,
        desc = 'Move cursor up',
      },
      {
        '<C-l>',
        mode = 'n',
        function()
          require('smart-splits').move_cursor_right()
        end,
        desc = 'Move cursor right',
      },
    },
  },
  {
    -- Autopair quotes, brackets, etc
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    opts = {},
  },
  {
    -- Surround motions
    'kylechui/nvim-surround',
    version = '*',
    event = 'BufEnter',
    opts = {},
  },
  {
    -- Go to normal mode with jk
    'max397574/better-escape.nvim',
    event = 'InsertCharPre',
    opts = {},
  },
  {
    -- "gc" to comment visual regions/lines
    'numToStr/Comment.nvim',
    event = 'BufEnter',
    opts = {},
  },
  {
    -- Useful plugin to show you pending keybinds.
    'folke/which-key.nvim',
    opts = {},
    event = 'VeryLazy',
    init = function()
      -- document existing key chains
      require('which-key').register {
        ['<leader>l'] = { name = 'LSP', _ = 'which_key_ignore' },
        ['<leader>d'] = { name = 'Debugger', _ = 'which_key_ignore' },
        ['<leader>g'] = { name = 'Git', _ = 'which_key_ignore' },
        ['<leader>b'] = { name = 'Buffers', _ = 'which_key_ignore' },
        ['<leader>f'] = { name = 'Find', _ = 'which_key_ignore' },
        ['<leader>t'] = { name = 'Test', _ = 'which_key_ignore' },
      }
    end,
  },
  {
    -- Detect indentation
    'nmac427/guess-indent.nvim',
    opts = {},
    event = 'BufEnter',
  },
}
