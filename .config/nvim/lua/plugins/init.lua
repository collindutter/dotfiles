return {
  {
    'echasnovski/mini.bufremove',
    version = '*',
    keys = require 'plugins.keys.bufremove',
  },
  {
    -- Better window resizing, navigation (integrates with tmux)
    'mrjones2014/smart-splits.nvim',
    opts = {},
    keys = require 'plugins.keys.smart-splits',
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
    -- Comment visual regions/lines
    'numToStr/Comment.nvim',
    event = 'BufEnter',
    opts = {},
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
    -- Detect indentation
    'nmac427/guess-indent.nvim',
    opts = {},
    event = 'BufEnter',
  },
  {
    -- Better quickfix
    'kevinhwang91/nvim-bqf',
    opts = {},
    event = 'BufEnter',
  },
  {
    -- Test runner
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'nvim-neotest/neotest-python',
    },
    keys = require 'plugins.keys.neotest',
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
  {
    -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    event = 'BufEnter',
    dependencies = {
      -- Install LSPs to stdpath for neovim
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',

      -- Useful status updates for LSP
      { 'j-hui/fidget.nvim', tag = 'legacy', opts = {} },

      -- Additional lua configuration
      'folke/neodev.nvim',
    },
    opts = {
      diagnostic_config = {
        virtual_text = false,
        update_in_insert = true,
        underline = true,
        severity_sort = true,
        float = {
          -- focusable = false,
          style = 'minimal',
          border = 'rounded',
          source = 'always',
          header = '',
          prefix = '',
        },
      },
      mason_ensure_installed = {
        'stylua',
        'luacheck',
      },
      mason_lspconfig_ensure_installed = {
        ruff_lsp = {},
        jsonls = {},
        pyright = {
          python = {
            pythonPath = '.venv/bin/python',
          },
        },
        tsserver = {},
        html = {},
        yamlls = {
          yaml = {
            customTags = {
              '!And scalar',
              '!And mapping',
              '!And sequence',
              '!If scalar',
              '!If mapping',
              '!If sequence',
              '!Not scalar',
              '!Not mapping',
              '!Not sequence',
              '!Equals scalar',
              '!Equals mapping',
              '!Equals sequence',
              '!Or scalar',
              '!Or mapping',
              '!Or sequence',
              '!FindInMap scalar',
              '!FindInMap mapping',
              '!FindInMap sequence',
              '!Base64 scalar',
              '!Base64 mapping',
              '!Base64 sequence',
              '!Cidr scalar',
              '!Cidr mapping',
              '!Cidr sequence',
              '!Ref scalar',
              '!Ref mapping',
              '!Ref sequence',
              '!Sub scalar',
              '!Sub mapping',
              '!Sub sequence',
              '!GetAtt scalar',
              '!GetAtt mapping',
              '!GetAtt sequence',
              '!GetAZs scalar',
              '!GetAZs mapping',
              '!GetAZs sequence',
              '!ImportValue scalar',
              '!ImportValue mapping',
              '!ImportValue sequence',
              '!Select scalar',
              '!Select mapping',
              '!Select sequence',
              '!Split scalar',
              '!Split mapping',
              '!Split sequence',
              '!Join scalar',
              '!Join mapping',
              '!Join sequence',
            },
          },
        },
        lua_ls = {
          Lua = {
            telemetry = { enable = false },
            completion = {
              callSnippet = 'Replace',
            },
            diagnostics = {
              globals = { 'vim' },
            },
            workspace = {
              checkThirdParty = false,
              library = {
                [vim.fn.expand '$VIMRUNTIME/lua'] = true,
                [vim.fn.stdpath 'config' .. '/lua'] = true,
              },
            },
          },
        },
      },
    },
    config = require 'plugins.configs.lsp',
  },
  {
    -- Autocompletion
    'hrsh7th/nvim-cmp',
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',

      -- LSP completion capabilities
      'hrsh7th/cmp-nvim-lsp',

      -- Copilot
      'zbirenbaum/copilot.lua',
    },
    config = require 'plugins.configs.cmp',
    event = 'InsertEnter',
  },
  {
    -- Copilot
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    opts = {
      panel = { enabled = false },
      suggestion = {
        auto_trigger = true,
        debounce = 150,
      },
      filetypes = { yaml = true, markdown = true, help = true },
    },
  },
  {
    -- Formatter
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        python = { 'black' },
        lua = { 'stylua' },
      },
    },
    keys = require 'plugins.keys.conform',
  },
  {
    -- Easy motion
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = { modes = { search = { enabled = false } } },
    keys = require 'plugins.keys.flash',
  },
  {
    -- Adds git related signs to the gutter
    'lewis6991/gitsigns.nvim',
    event = 'BufEnter',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },
  {
    -- Linter
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'

      lint.linters_by_ft = {
        python = { 'ruff' },
        lua = { 'luacheck' },
      }

      vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
        callback = function()
          require('lint').try_lint()
        end,
      })
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
    keys = require 'plugins.keys.oil',
  },
  {
    -- Move by subwords
    'chrisgrieser/nvim-spider',
    opts = { skipInsignificantPunctuation = false },
    keys = require 'plugins.keys.spider',
    init = function()
      vim.keymap.set({ 'n', 'o', 'x' }, 'cw', 'ce', { desc = 'Spider-ce', remap = true })
    end,
  },
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
    keys = require 'plugins.keys.telescope',
    config = require 'plugins.configs.telescope',
  },
  {
    -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    build = ':TSUpdate',
    event = 'BufEnter',
    config = require 'plugins.configs.treesitter',
  },
  {
    -- Better ui elements
    'stevearc/dressing.nvim',
    event = 'BufEnter',
    opts = {
      input = { default_prompt = '➤ ', mappings = {
        n = {
          ['q'] = 'Close',
        },
      } },
      select = { backend = { 'telescope', 'builtin' } },
    },
  },
  {
    -- Tabs for buffers (sue me)
    'akinsho/bufferline.nvim',
    version = '*',
    dependencies = 'nvim-tree/nvim-web-devicons',
    event = 'BufEnter',
    opts = {},
    keys = require 'plugins.keys.bufferline',
  },
  {
    -- Indentation guides
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    event = 'BufEnter',
    opts = {
      exclude = {
        filetypes = {
          'help',
          'alpha',
          'dashboard',
          'neo-tree',
          'Trouble',
          'lazy',
          'mason',
          'notify',
          'toggleterm',
          'lazyterm',
        },
      },
    },
  },
  {
    -- Catpuccin theme
    'catppuccin/nvim',
    priority = 1000,
    lazy = false,
    config = require 'plugins.configs.colorscheme',
  },
  {
    -- Better statusline
    'nvim-lualine/lualine.nvim',
    event = 'BufEnter',
    opts = {
      options = {
        component_separators = '|',
        section_separators = { right = '' },
      },
    },
  },
  {
    -- Center buffer without noise
    'folke/zen-mode.nvim',
    keys = require 'plugins.keys.zen-mode',
    opts = {},
  },
}
