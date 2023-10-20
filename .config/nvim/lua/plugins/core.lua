-- Plugins for fixing Neovim basics
return {
  {
    -- Go to normal mode with jk
    'max397574/better-escape.nvim',
    event = 'InsertCharPre',
    opts = {},
  },
  {
    -- Better buffer deletion, preserves window layout
    'echasnovski/mini.bufremove',
    version = '*',
    keys = {
      {
        '<leader>bc',
        function()
          require('mini.bufremove').delete(0, false)
        end,
        desc = 'Buffer close',
      },
      {
        '<leader>bC',
        function()
          require('mini.bufremove').delete(0, true)
        end,
        desc = 'Buffer force close',
      },
    },
  },
  {
    -- Better window resizing, navigation (integrates with tmux)
    'mrjones2014/smart-splits.nvim',
    opts = {},
    keys = {
      -- resizing splits
      {
        '<C-Left>',
        function()
          require('smart-splits').resize_left()
        end,
        desc = 'Resize left',
      },
      {
        '<C-Down>',
        function()
          require('smart-splits').resize_down()
        end,
        desc = 'Resize down',
      },
      {
        '<C-Up>',
        function()
          require('smart-splits').resize_up()
        end,
        desc = 'Resize up',
      },
      {
        '<C-Right>',
        function()
          require('smart-splits').resize_right()
        end,
        desc = 'Resize right',
      },
      -- moving between splits
      {
        '<C-h>',
        function()
          require('smart-splits').move_cursor_left()
        end,
        desc = 'Move cursor left',
      },
      {
        '<C-j>',
        function()
          require('smart-splits').move_cursor_down()
        end,
        desc = 'Move cursor down',
      },
      {
        '<C-k>',
        function()
          require('smart-splits').move_cursor_up()
        end,
        desc = 'Move cursor up',
      },
      {
        '<C-l>',
        function()
          require('smart-splits').move_cursor_right()
        end,
        desc = 'Move cursor right',
      },
    },
  },
  {
    -- Detect indentation
    'nmac427/guess-indent.nvim',
    opts = {},
    event = 'BufEnter',
  },
  {
    'folke/neodev.nvim',
    event = 'BufEnter',
    opts = {
      library = { plugins = { 'neotest' }, types = true },
    },
  },
}
