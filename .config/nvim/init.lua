vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Install package manager
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

-- [[ Plugins ]]
require('lazy').setup({
  {
    -- Detect tabstop and shiftwidth automatically
    'tpope/vim-sleuth',
  },
  {
    -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    event="BufEnter",
    dependencies = {
      -- Automatically install LSPs to stdpath for neovim
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',

      -- Useful status updates for LSP
      { 'j-hui/fidget.nvim', tag = 'legacy', opts = {} },

      -- Additional lua configuration, makes nvim stuff amazing!
      'folke/neodev.nvim',
    },
  },
  {
    -- Autocompletion
    'hrsh7th/nvim-cmp',
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',

      -- Adds LSP completion capabilities
      'hrsh7th/cmp-nvim-lsp',
    },
    event="InsertEnter",
    config = function()
      -- [[ Configure nvim-cmp ]]
      -- See `:help cmp`
      local cmp = require 'cmp'
      local luasnip = require 'luasnip'
      require('luasnip.loaders.from_vscode').lazy_load()
      luasnip.config.setup {}

      cmp.setup {
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert {
          ['<C-n>'] = cmp.mapping.select_next_item(),
          ['<C-p>'] = cmp.mapping.select_prev_item(),
          ['<C-d>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete {},
          ['<CR>'] = cmp.mapping.confirm {
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
          },
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        },
        sources = {
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
        },
      }
    end
  },

  {
    -- Useful plugin to show you pending keybinds.
    'folke/which-key.nvim',
    opts = {},
    init = function()
      -- document existing key chains
      require('which-key').register {
        ['<leader>l'] = { name = 'LSP', _ = 'which_key_ignore' },
        ['<leader>d'] = { name = 'Debugger', _ = 'which_key_ignore' },
        ['<leader>g'] = { name = 'Git', _ = 'which_key_ignore' },
        ['<leader>b'] = { name = 'Buffers', _ = 'which_key_ignore' },
        ['<leader>f'] = { name = 'Find', _ = 'which_key_ignore' },
      }
    end
  },
  {
    -- Adds git related signs to the gutter
    'lewis6991/gitsigns.nvim',
    event="BufEnter",
    opts = {
      -- See `:help gitsigns.txt`
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
    -- Catpuccin theme
    'catppuccin/nvim',
    priority = 1000,
    lazy=false,
    config = function()
      vim.cmd.colorscheme 'catppuccin-macchiato'
    end,
  },
  {
    -- Set lualine as statusline
    'nvim-lualine/lualine.nvim',
    event="BufEnter",
    -- See `:help lualine.txt`
    opts = {
      options = {
        icons_enabled = false,
        theme = 'auto',
        component_separators = '|',
        section_separators = '',
      },
    },
  },
  {
    -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help ibl`
    main = 'ibl',
    event="BufEnter",
    opts = {},
  },
  {
    -- "gc" to comment visual regions/lines
    'numToStr/Comment.nvim',
    event="BufEnter",
    opts = {},
  },
  {
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
    config = function()
      -- [[ Configure Telescope ]]
      -- See `:help telescope` and `:help telescope.setup()`
      local actions = require "telescope.actions"
      require('telescope').setup {
        defaults = {
          git_worktrees = vim.g.git_worktrees,
          path_display = { "truncate" },
          sorting_strategy = "ascending",
          layout_config = {
            horizontal = {
              prompt_position = "top",
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
              ["<C-n>"] = actions.cycle_history_next,
              ["<C-p>"] = actions.cycle_history_prev,
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
            },
            n = {
              ["q"] = actions.close,
              ['d'] = "delete_buffer"
            },
          },
        },
      }

      -- Enable telescope fzf native, if installed
      pcall(require('telescope').load_extension, 'fzf')

      -- See `:help telescope.builtin`
      vim.keymap.set('n', '<leader>fg', require('telescope.builtin').git_files, { desc = '[f]ind [g]it' })
      vim.keymap.set('n', '<leader>fb', require('telescope.builtin').buffers, { desc = '[f]ind [b]uffers' })
      vim.keymap.set('n', '<leader>fo', require('telescope.builtin').oldfiles, { desc = '[f]ind [o]ld files' })
      vim.keymap.set('n', '<leader>ff', require('telescope.builtin').find_files, { desc = '[f]ind [f]iles' })
      vim.keymap.set('n', '<leader>fh', require('telescope.builtin').help_tags, { desc = '[f]ind [h]elp' })
      vim.keymap.set('n', '<leader>fc', require('telescope.builtin').grep_string, { desc = '[f]ind [c]urrent word' })
      vim.keymap.set('n', '<leader>fw', require('telescope.builtin').live_grep, { desc = '[f]ind [w]word' })
      vim.keymap.set('n', '<leader>fd', require('telescope.builtin').diagnostics, { desc = '[f]ind [d]iagnostics' })
      vim.keymap.set('n', '<leader>fr', require('telescope.builtin').resume, { desc = '[f]ind [r]esume' })
      vim.keymap.set('n', '<leader>fa',
        function()
          require("telescope.builtin").find_files {
            prompt_title = "Config Files",
            search_file = "init.lua",
            cwd = '~/.config',
          }
        end, { desc = "[f]ind [a] config" }
      )
    end
  },
  -- Highlight, edit, and navigate code
  {
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    build = ':TSUpdate',
    event="BufEnter",
    config = function()
      -- [[ Configure Treesitter ]]
      -- See `:help nvim-treesitter`
      -- Defer Treesitter setup after first render to improve startup time of 'nvim {filename}'
      vim.defer_fn(function()
        require('nvim-treesitter.configs').setup {
          -- Add languages to be installed here that you want installed for treesitter
          ensure_installed = "all",

          -- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
          auto_install = false,
          modules = {},
          sync_install = false,
          ignore_install = {},

          highlight = { enable = true },
          indent = { enable = true },
          incremental_selection = {
            enable = true,
            keymaps = {
              init_selection = '<c-space>',
              node_incremental = '<c-space>',
              scope_incremental = '<c-s>',
              node_decremental = '<M-space>',
            },
          },
          textobjects = {
            select = {
              enable = true,
              lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
              keymaps = {
                -- You can use the capture groups defined in textobjects.scm
                ['aa'] = '@parameter.outer',
                ['ia'] = '@parameter.inner',
                ['af'] = '@function.outer',
                ['if'] = '@function.inner',
                ['ac'] = '@class.outer',
                ['ic'] = '@class.inner',
              },
            },
            move = {
              enable = true,
              set_jumps = true, -- whether to set jumps in the jumplist
              goto_next_start = {
                [']m'] = '@function.outer',
                [']]'] = '@class.outer',
              },
              goto_next_end = {
                [']M'] = '@function.outer',
                [']['] = '@class.outer',
              },
              goto_previous_start = {
                ['[m'] = '@function.outer',
                ['[['] = '@class.outer',
              },
              goto_previous_end = {
                ['[M'] = '@function.outer',
                ['[]'] = '@class.outer',
              },
            },
            swap = {
              enable = true,
              swap_next = {
                ['<leader>a'] = '@parameter.inner',
              },
              swap_previous = {
                ['<leader>A'] = '@parameter.inner',
              },
            },
          },
        }
      end, 0)

      -- Diagnostic keymaps
      vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
      vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
      vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
      vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })
    end
  },
  {
    -- Go to normal mode with jk
    "max397574/better-escape.nvim",
    event="InsertCharPre",
    opts = {}
  },
  {
    -- Move by subwords
    "chrisgrieser/nvim-spider",
    opts = { skipInsignificantPunctuation = false },
    keys = {
      {
        "w", function() require("spider").motion("w") end, mode = {"n", "o", "x"}, desc="Spider-w",
      },
      {
        "e", function() require("spider").motion("e") end, mode = {"n", "o", "x"}, desc="Spider-e",
      },
      {
        "b", function() require("spider").motion("b") end, mode = {"n", "o", "x"}, desc="Spider-b",
      },
      {
        "ge", function() require("spider").motion("ge") end, mode = {"n", "o", "x"}, desc="Spider-ge",
      }
    },
    init = function()
      vim.keymap.set({ "n", "o", "x" }, "cw", "ce",
        { desc = "Spider-ce", remap = true })
    end,
  },
  {
    -- Center buffer without noise
    "folke/zen-mode.nvim",
    opts = {},
    keys={
      { "<leader>m", mode="n",  function() require("zen-mode").toggle({}) end, desc="Toggle Zen Mode"}
    },
  },
  {
    -- Easy motion
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end,       desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    },
  },
  {
    -- Surround motions
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    opts = {}
  },
  {
    -- Autopair quotes, brackets, etc
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    opts = {}
  },
  {
    'mrjones2014/smart-splits.nvim',
    opts = {},
    keys = {
      -- resizing splits
      {"<C-Left>", mode="n", function() require("smart-splits").resize_left() end , desc="Resize left"},
      {"<C-Down>", mode="n", function() require("smart-splits").resize_down() end,  desc="Resize down"},
      {"<C-Up>", mode="n", function() require("smart-splits").resize_up() end,  desc="Resize up"},
      {"<C-Right>", mode="n", function() require("smart-splits").resize_right() end,  desc="Resize right"},
      -- moving between splits
      {"<C-h>", mode="n", function() require("smart-splits").move_cursor_left() end,  desc="Move cursor left"},
      {"<C-j>", mode="n", function() require("smart-splits").move_cursor_down() end,  desc="Move cursor down"},
      {"<C-k>", mode="n", function() require("smart-splits").move_cursor_up() end,  desc="Move cursor up"},
      {"<C-l>", mode="n", function() require("smart-splits").move_cursor_right() end,  desc="Move cursor right"},
    }
  },
}, {
    defaults = {
      lazy = true
    }
  })

-- [[ LSP ]]
local on_attach = function(_, bufnr)
  local nmap = function(keys, func, desc)
    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
  end

  nmap('<leader>lr', vim.lsp.buf.rename, 'Rename current symbol')
  nmap('<leader>la', vim.lsp.buf.code_action, 'Code action')

  nmap('gd', vim.lsp.buf.definition, 'Goto definition')
  nmap('gD', vim.lsp.buf.declaration, 'Goto declartion')
  nmap('gr', require('telescope.builtin').lsp_references, 'Goto references')
  nmap('gI', require('telescope.builtin').lsp_implementations, 'Goto implementation')

  -- See `:help K` for why this keymap
  nmap('K', vim.lsp.buf.hover, 'Hover documentation')
  nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature documentation')

  -- nmap('<leader>lf', vim.lsp.buf.format(), 'Format buffer')
end

-- mason-lspconfig requires that these setup functions are called in this order
-- before setting up the servers.
require('mason').setup()
require('mason-lspconfig').setup()

local servers = {
  ruff_lsp = {},
  jsonls = {},
  pyright = {},
  tsserver = {},
  html = {},
  lua_ls = {
    Lua = {
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    },
  },
}

-- Setup neovim lua configuration
require('neodev').setup()

-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- Ensure the servers above are installed
local mason_lspconfig = require 'mason-lspconfig'

mason_lspconfig.setup {
  ensure_installed = vim.tbl_keys(servers),
}

mason_lspconfig.setup_handlers {
  function(server_name)
    require('lspconfig')[server_name].setup {
      capabilities = capabilities,
      on_attach = on_attach,
      settings = servers[server_name],
      filetypes = (servers[server_name] or {}).filetypes,
    }
  end,
}


-- [[ Options ]]
-- See `:help vim.opt`
-- NOTE: You can change these options as you wish!

-- Set highlight on search
vim.opt.hlsearch = false

-- Make line numbers default
vim.opt.number = true

-- Enable relative line numbers
vim.opt.relativenumber = true

-- Enable mouse mode
vim.opt.mouse = 'a'

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.opt.clipboard = 'unnamedplus'

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

-- Decrease update time
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.opt.completeopt = 'menuone,noselect'

-- NOTE: You should make sure your terminal supports this
vim.opt.termguicolors = true

-- Set shell to bash (fish doesn't work well)
vim.opt.shell = '/bin/bash'
-- Hide command line unless needed
vim.opt.cmdheight = 0


-- [[ Keymaps ]]
-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Center buffer after moving up or down
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Center cursor after moving down half-page" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Center cursor after moving up half-page" })

-- Tab movement
vim.keymap.set("n", "]t", function() vim.cmd.tabnext() end, { desc = "Next tab" })
vim.keymap.set("n", "[t", function() vim.cmd.tabprevious() end, { desc = "Previous tab" })

vim.keymap.set("n", "|", "<cmd>vsplit<cr>", { desc = 'Vertical split' })
vim.keymap.set("n", "\\", "<cmd>split<cr>", { desc = 'Horizontal split' })

-- [[ Autocommands ]]
-- Highlight on yank
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = "Highlight on yank",
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- Better close
vim.api.nvim_create_autocmd("BufWinEnter", {
  desc = "Make q close help, man, quickfix, dap floats",
  group = vim.api.nvim_create_augroup("q_close_windows", { clear = true }),
  callback = function(args)
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = args.buf })
    if vim.tbl_contains({ "help", "nofile", "quickfix" }, buftype) and vim.fn.maparg("q", "n") == "" then
      vim.keymap.set("n", "q", "<cmd>close<cr>", {
        desc = "Close window",
        buffer = args.buf,
        silent = true,
        nowait = true,
      })
    end
  end,
})

-- Restore cursor position
vim.api.nvim_create_autocmd('BufRead', {
  desc = "Restore cursor position",
  callback = function(opts)
    vim.api.nvim_create_autocmd('BufWinEnter', {
      once = true,
      buffer = opts.buf,
      callback = function()
        local ft = vim.bo[opts.buf].filetype
        local last_known_line = vim.api.nvim_buf_get_mark(opts.buf, '"')[1]
        if
          not (ft:match('commit') and ft:match('rebase'))
          and last_known_line > 1
          and last_known_line <= vim.api.nvim_buf_line_count(opts.buf)
        then
          vim.api.nvim_feedkeys([[g`"]], 'nx', false)
        end
      end,
    })
  end,
})

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
