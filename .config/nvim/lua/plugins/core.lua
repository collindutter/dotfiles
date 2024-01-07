-- Plugins for fixing Neovim basics
return {
  {
    -- Go to normal mode with jk
    'max397574/better-escape.nvim',
    opts = {},
  },
  {
    -- Better buffer deletion, preserves window layout
    'famiu/bufdelete.nvim',
    version = '*',
    init = function()
      local map = require('helpers.keys').map
      map('n', '<leader>bc', function()
        require('bufdelete').bufdelete(0, true)
      end, 'Buffer close')
      map('n', '<leader>bo', function()
        local bufdelete = require 'bufdelete'
        local buflist = vim.api.nvim_list_bufs()
        local curbufnr = vim.api.nvim_get_current_buf()
        for _, bufnr in ipairs(buflist) do
          if vim.bo[bufnr].buflisted and bufnr ~= curbufnr and (vim.fn.getbufvar(bufnr, 'bufpersist') ~= 1) then
            bufdelete.bufdelete(bufnr, true)
          end
        end
      end, 'Buffer close others')
    end,
  },
  {
    -- Better window resizing, navigation (integrates with tmux)
    'mrjones2014/smart-splits.nvim',
    opts = {},
    init = function()
      local map = require('helpers.keys').map

      -- resizing splits
      map('n', '<C-Left>', function()
        require('smart-splits').resize_left()
      end, 'Resize left')
      map('n', '<C-Down>', function()
        require('smart-splits').resize_down()
      end, 'Resize down')
      map('n', '<C-Up>', function()
        require('smart-splits').resize_up()
      end, 'Resize up')
      map('n', '<C-Right>', function()
        require('smart-splits').resize_right()
      end, 'Resize right')
      -- moving between splits
      map('n', '<C-h>', function()
        require('smart-splits').move_cursor_left()
      end, 'Move cursor left')
      map('n', '<C-j>', function()
        require('smart-splits').move_cursor_down()
      end, 'Move cursor down')
      map('n', '<C-k>', function()
        require('smart-splits').move_cursor_up()
      end, 'Move cursor up')
      map('n', '<C-l>', function()
        require('smart-splits').move_cursor_right()
      end, 'Move cursor right')
    end,
  },
  {
    -- Detect indentation
    'nmac427/guess-indent.nvim',
    opts = {},
  },
  {
    -- Neovim lua development tools
    'folke/neodev.nvim',
    opts = {
      library = { plugins = { 'neotest' }, types = true },
    },
  },
  {
    -- Better session management
    'folke/persistence.nvim',
    event = 'BufReadPre',
    opts = {},
    init = function()
      local map = require('helpers.keys').map
      map('n', '<leader>sd', function()
        require('persistence').load()
      end, 'Restore directory session')

      map('n', '<leader>sl', function()
        require('persistence').load { last = true }
      end, 'Restore last session')
    end,
  },
  {
    -- Big file support, big file support, big file support
    'LunarVim/bigfile.nvim',
    opts = {},
  },
  {
    -- Preserve window ratios after tmuxing
    'kwkarlwang/bufresize.nvim',
    opts = {
      register = {
        trigger_events = { 'BufWinEnter', 'WinEnter', 'WinResized' },
      },
      resize = {
        keys = {},
        trigger_events = { 'VimResized' },
        increment = false,
      },
    },
  },
}
