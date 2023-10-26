-- Plugins that provide new editor UI components
return {
  {
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
      {
        'nvim-telescope/telescope-frecency.nvim',
      },
      {
        'nvim-telescope/telescope-live-grep-args.nvim',
      },
    },
    init = function()
      local map = require('helpers.keys').map

      map('n', '<leader>fg', function()
        require('telescope.builtin').git_files()
      end, 'Find files')
      map('n', '<leader>fb', function()
        require('telescope.builtin').buffers { sort_mru = true, ignore_current_buffer = true }
      end, 'Find buffers')
      map('n', '<leader>fO', function()
        vim.cmd 'Telescope frecency'
      end, 'Find old files (frecency)')
      map('n', '<leader>fo', function()
        require('telescope.builtin').oldfiles()
      end, 'Find old files')
      map('n', '<leader>ff', function()
        require('telescope.builtin').find_files()
      end, 'Find files')
      map('n', '<leader>fh', function()
        require('telescope.builtin').help_tags()
      end, 'Find help')
      map('n', '<leader>fc', function()
        require('telescope.builtin').grep_string()
      end, 'Find current word')
      map('n', '<leader>fw', function()
        require('telescope.builtin').live_grep()
      end, 'Find word')
      map('n', '<leader>fW', function()
        vim.cmd 'lua require("telescope").extensions.live_grep_args.live_grep_args()'
      end, 'Find word with args')
      map('n', '<leader>fd', function()
        require('telescope.builtin').diagnostics()
      end, 'Find diagnostics')
      map('n', '<leader>fr', function()
        require('telescope.builtin').resume()
      end, 'Find resume')
      map('n', '<leader>fa', function()
        require('telescope.builtin').find_files {
          prompt_title = 'Config Files',
          hidden = true,
          cwd = '~/.config/nvim',
        }
      end, 'Find a config')
    end,
    config = function()
      local actions = require 'telescope.actions'
      require('telescope').setup {
        defaults = {
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
              ['dd'] = actions.delete_buffer,
            },
          },
        },
        extentions = {
          frecency = {
            db_safe_mode = false
          },
        }
      }

      require('telescope').load_extension 'fzf'
      require('telescope').load_extension 'frecency'
      require('telescope').load_extension 'live_grep_args'
    end,
  },
  {
    -- File explorer as buffer
    'stevearc/oil.nvim',
    opts = {
      keymaps = {
        ['<C-l>'] = false,
        ['<C-h>'] = false,
        ['q'] = 'actions.close',
        ['H'] = 'actions.toggle_hidden',
      },
    },
    init = function()
      local map = require('helpers.keys').map

      map('n', '-', function()
        require('oil').open()
      end, 'Open Oil')
    end,
  },
  {
    -- Show pending keybinds
    'folke/which-key.nvim',
    opts = {},
    init = function()
      -- Document existing key chains
      require('which-key').register {
        ['<leader>c'] = { name = 'Code', _ = 'which_key_ignore' },
        ['<leader>d'] = { name = 'Debugger', _ = 'which_key_ignore' },
        ['<leader>g'] = { name = 'Git', _ = 'which_key_ignore' },
        ['<leader>b'] = { name = 'Buffers', _ = 'which_key_ignore' },
        ['<leader>f'] = { name = 'Find', _ = 'which_key_ignore' },
        ['<leader>t'] = { name = 'Test', _ = 'which_key_ignore' },
      }
    end,
  },
  {
    -- Center buffer without noise
    'folke/zen-mode.nvim',
    init = function()
      local map = require('helpers.keys').map

      map('n', '<leader>m', function()
        require('zen-mode').toggle {}
      end, 'Toggle Zen Mode')
    end,
    opts = {
      window = {
        width = 160,
      },
      plugins = {
        tmux = { enabled = true },
      },
    },
  },
  {
    -- Diagnostics signs and list
    'folke/trouble.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    init = function()
      local map = require('helpers.keys').map

      map('n', '<leader>xx', function()
        require('trouble').toggle()
      end, 'Trouble toggle')

      map('n', '<leader>xw', function()
        require('trouble').toggle 'workspace_diagnostics'
      end, 'Trouble workspace diagnostics')

      map('n', '<leader>xd', function()
        require('trouble').toggle 'document_diagnostics'
      end, 'Trouble document diagnostics')

      map('n', '<leader>xq', function()
        require('trouble').toggle 'quickfix'
      end, 'Trouble quickfix')

      map('n', '<leader>xl', function()
        require('trouble').toggle 'loclist'
      end, 'Trouble loclist')

      map('n', 'gR', function()
        require('trouble').toggle 'lsp_references'
      end, 'Trouble lsp lsp references')
    end,
    opts = {},
  },
  {
    -- Test runner
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'nvim-neotest/neotest-python',
    },
    init = function()
      local map = require('helpers.keys').map

      map('n', '<leader>tc', function()
        require('neotest').run.run(vim.fn.expand '%')
      end, 'Test current file')

      map('n', '<leader>tn', function()
        require('neotest').run.run()
      end, 'Test nearest')

      map('n', '<leader>td', function()
        require('neotest').run.run {
          suite = false,
          strategy = 'dap',
        }
      end, 'Test debug')

      map('n', '<leader>dt', function()
        require('neotest').run.run {
          suite = false,
          strategy = 'dap',
        }
      end, 'Debug test')

      map('n', '<leader>ts', function()
        require('neotest').run.stop()
      end, 'Test stop')

      map('n', '<leader>tu', function()
        require("neotest").output_panel.toggle()
      end, 'Test UI')
    end,
    opts = function()
      return {
        adapters = {
          require 'neotest-python' {
            dap = { justMyCode = false },
          },
        },
      }
    end,
  },
}
