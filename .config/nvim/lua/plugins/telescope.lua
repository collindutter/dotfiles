return {
  -- Fuzzy Finder (files, lsp, etc)
  'nvim-telescope/telescope.nvim',
  branch = '0.1.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
  },
  init = function()
    local map = require('helpers.keys').map

    map('n', '<leader>fg', function()
      require('telescope.builtin').git_files()
    end, '[f]ind [g]it files')
    map('n', '<leader>fb', function()
      require('telescope.builtin').buffers { sort_mru = true, ignore_current_buffer = true }
    end, '[f]ind [b]uffers')
    map('n', '<leader>fo', function()
      require('telescope.builtin').oldfiles()
    end, '[f]ind [o]ld files')
    map('n', '<leader>ff', function()
      require('telescope.builtin').find_files()
    end, '[f]ind [f]iles')
    map('n', '<leader>fh', function()
      require('telescope.builtin').help_tags()
    end, '[f]ind [h]elp')
    map('n', '<leader>fc', function()
      require('telescope.builtin').grep_string()
    end, '[f]ind [c]current word')
    map('n', '<leader>fw', function()
      require('telescope.builtin').live_grep()
    end, '[f]ind [w]ord')
    map('n', '<leader>fr', function()
      require('telescope.builtin').resume()
    end, '[f]ind [r]esume')
  end,
  config = function()
    local actions = require 'telescope.actions'
    local telescope = require 'telescope'

    telescope.setup {
      defaults = {
        prompt_prefix = '  ',
        path_display = { 'truncate' },
        sorting_strategy = 'ascending',
        layout_config = {
          horizontal = {
            prompt_position = 'top',
            preview_width = 0.55,
          },
          vertical = {
            mirror = false,
          },
          width = 0.87,
          height = 0.80,
          preview_cutoff = 120,
        },
        mappings = {
          n = {
            ['q'] = actions.close,
          },
        },
      },
    }

    require('telescope').load_extension 'fzf'
  end,
}
