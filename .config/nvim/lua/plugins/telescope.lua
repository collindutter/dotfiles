return {
  -- Fuzzy Finder (files, lsp, etc)
  'nvim-telescope/telescope.nvim',
  branch = '0.1.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    -- Fuzzy Finder Algorithm which requires local dependencies to be built.
    -- Only load if `make` is available. Make sure you have the system
    -- requirements installed.
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      -- NOTE: If you are having trouble with this installation,
      --       refer to the README for telescope-fzf-native for more instructions.
      build = 'make',
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
  },
  keys = {
    {
      '<leader>fg',
      function()
        require('telescope.builtin').git_files()
      end,
      desc = '[f]ind [g]it',
    },
    {
      '<leader>fb',
      function()
        require('telescope.builtin').buffers()
      end,
      desc = '[f]ind [b]uffers',
    },
    {
      '<leader>fo',
      function()
        require('telescope.builtin').oldfiles()
      end,
      desc = '[f]ind [o]ld files',
    },
    {
      '<leader>ff',
      function()
        require('telescope.builtin').find_files()
      end,
      desc = '[f]ind [f]iles',
    },
    {
      '<leader>fh',
      function()
        require('telescope.builtin').help_tags()
      end,
      desc = '[f]ind [h]elp',
    },
    {
      '<leader>fc',
      function()
        require('telescope.builtin').grep_string()
      end,
      desc = '[f]ind [c]urrent word',
    },
    {
      '<leader>fw',
      function()
        require('telescope.builtin').live_grep()
      end,
      desc = '[f]ind [w]ord',
    },
    {
      '<leader>fd',
      function()
        require('telescope.builtin').diagnostics()
      end,
      desc = '[f]ind [d]iagnostics',
    },
    {
      '<leader>fr',
      function()
        require('telescope.builtin').resume()()
      end,
      desc = '[f]ind [r]esume',
    },
    {
      '<leader>fa',
      function()
        require('telescope.builtin').find_files {

          prompt_title = 'Config Files',
          hidden = true,
          cwd = '~/.config/nvim',
        }
      end,
      desc = '[f]ind [a] config',
    },
  },
  config = function()
    -- [[ Configure Telescope ]]
    local actions = require 'telescope.actions'
    require('telescope').setup {
      defaults = {
        git_worktrees = vim.g.git_worktrees,
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
          i = {
            ['<C-n>'] = actions.cycle_history_next,
            ['<C-p>'] = actions.cycle_history_prev,
            ['<C-j>'] = actions.move_selection_next,
            ['<C-k>'] = actions.move_selection_previous,
          },
          n = {
            ['q'] = actions.close,
          },
        },
      },
    }

    -- Enable telescope fzf native, if installed
    pcall(require('telescope').load_extension, 'fzf')
  end,
}
