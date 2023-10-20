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
    },
    keys = {
      {
        '<leader>fg',
        function()
          require('telescope.builtin').git_files()
        end,
        desc = 'Find Git',
      },
      {
        '<leader>fb',
        function()
          require('telescope.builtin').buffers()
        end,
        desc = 'Find buffers',
      },
      {
        '<leader>fo',
        function()
          require('telescope.builtin').oldfiles()
        end,
        desc = 'Find old files',
      },
      {
        '<leader>ff',
        function()
          require('telescope.builtin').find_files()
        end,
        desc = 'Find files',
      },
      {
        '<leader>fh',
        function()
          require('telescope.builtin').help_tags()
        end,
        desc = 'Find help',
      },
      {
        '<leader>fc',
        function()
          require('telescope.builtin').grep_string()
        end,
        desc = 'Find current word',
      },
      {
        '<leader>fw',
        function()
          require('telescope.builtin').live_grep()
        end,
        desc = 'Find words',
      },
      {
        '<leader>fd',
        function()
          require('telescope.builtin').diagnostics()
        end,
        desc = 'Find diagnostics',
      },
      {
        '<leader>fr',
        function()
          require('telescope.builtin').resume()
        end,
        desc = 'Find resume',
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
        desc = 'Find a config',
      },
    },
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
            },
          },
        },
      }

      require('telescope').load_extension 'fzf'
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
    keys = {
      {
        '-',
        '<cmd>Oil<cr>',
        desc = 'Open Oil',
      },
    },
  },
  {
    -- Show pending keybinds
    'folke/which-key.nvim',
    opts = {},
    event = 'VeryLazy',
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
    keys = {
      {
        '<leader>m',
        mode = 'n',
        function()
          require('zen-mode').toggle {}
        end,
        desc = 'Toggle Zen Mode',
      },
    },
    opts = {},
  },
  {
    -- Diagnostics signs and list
    'folke/trouble.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    keys = {
      -- Lua
      {
        '<leader>xx',
        function()
          require('trouble').toggle()
        end,
        desc = 'Trouble toggle',
      },
      {
        '<leader>xw',
        function()
          require('trouble').toggle 'workspace_diagnostics'
        end,
        desc = 'Trouble workspace diagnostics',
      },
      {
        '<leader>xd',
        function()
          require('trouble').toggle 'document_diagnostics'
        end,
        desc = 'Trouble document diagnostics',
      },
      {
        '<leader>xq',
        function()
          require('trouble').toggle 'quickfix'
        end,
        desc = 'Trouble quickfix',
      },
      {
        '<leader>xl',
        function()
          require('trouble').toggle 'loclist'
        end,
        desc = 'Trouble loclist',
      },
      {
        'gR',
        function()
          require('trouble').toggle 'lsp_references'
        end,
        desc = 'Trouble lsp lsp references',
      },
    },
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
    keys = {
      {
        '<leader>tc',
        function()
          require('neotest').run.run(vim.fn.expand '%')
        end,
        desc = 'Test current file',
      },
      {
        '<leader>td',
        function()
          require('neotest').run.run {
            suite = false,
            strategy = 'dap',
          }
        end,
        desc = 'Test debug',
      },
      {
        '<leader>dt',
        function()
          require('neotest').run.run {
            suite = false,
            strategy = 'dap',
          }
        end,
        desc = 'Debug test',
      },
      {
        '<leader>ts',
        function()
          require('neotest').run.stop()
        end,
        desc = 'Test stop',
      },
    },
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
