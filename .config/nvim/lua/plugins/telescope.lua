return {
  -- Fuzzy Finder (files, lsp, etc)
  'nvim-telescope/telescope.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
      config = function()
        require('telescope').load_extension 'fzf'
      end,
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
    {
      'danielfalk/smart-open.nvim',
      branch = '0.2.x',
      config = function()
        require('telescope').load_extension 'smart_open'
      end,
      dependencies = {
        'kkharji/sqlite.lua',
      },
    },
  },
  keys = {
    -- Find
    {
      '<leader>ff',
      function()
        require('telescope').extensions.smart_open.smart_open {
          cwd_only = true,
        }
      end,
      desc = '[f]ind [f]iles',
    },
    -- Grep
    {
      '<leader>sg',
      function()
        require('telescope.builtin').live_grep()
      end,
      desc = '[s]earch [g]rep',
    },
    {
      '<leader>sw',
      function()
        require('telescope.builtin').grep_string()
      end,
      mode = { 'n', 'x' },
      desc = '[s]earch [w]ord',
    },
    -- Search
    {
      '<leader>sh',
      function()
        require('telescope.builtin').help_tags()
      end,
      desc = '[s]earch [h]elp',
    },
    {
      '<leader>sR',
      function()
        require('telescope.builtin').resume()
      end,
      desc = '[s]earch [R]esume',
    },
    {
      '<leader>gr',
      function()
        require('telescope.builtin').lsp_references()
      end,
      desc = '[g]oto [r]eferences',
    },
    {
      '<leader>gi',
      function()
        require('telescope.builtin').lsp_implementations()
      end,
      desc = '[g]oto [i]mplementations',
    },
  },
  opts = function()
    local actions = require 'telescope.actions'

    return {
      defaults = {
        prompt_prefix = '  ',
        path_display = { 'truncate' },
        sorting_strategy = 'ascending',
        layout_config = {
          horizontal = {
            prompt_position = 'top',
          },
          vertical = {
            mirror = true,
          },
        },
        mappings = {
          n = {
            ['q'] = actions.close,
          },
        },
      },
    }
  end,
}
