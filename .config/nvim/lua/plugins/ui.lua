-- Plugins that change the UI of Neovim
return {
  {
    -- Catppuccin theme
    'catppuccin/nvim',
    name = 'catppuccin',
    config = function(_, opts)
      require('catppuccin').setup(opts)
      -- Don't forget to change in lazy.lua install
      vim.cmd.colorscheme 'catppuccin-macchiato'
    end,
    priority = 1000,
    opts = {
      flavour = 'macchiato',
      transparent_background = true,
      styles = {
        comments = {},
        conditionals = {},
      },
      integrations = {
        cmp = true,
        dap = {
          enabled = true,
          enable_ui = true,
        },
        flash = true,
        gitsigns = true,
        indent_blankline = { enabled = true },
        lsp_trouble = true,
        mason = true,
        native_lsp = {
          enabled = true,
          virtual_text = {
            errors = { 'italic' },
            hints = { 'italic' },
            warnings = { 'italic' },
            information = { 'italic' },
          },
          underlines = {
            errors = { 'undercurl' },
            hints = { 'undercurl' },
            warnings = { 'undercurl' },
            information = { 'undercurl' },
          },
          inlay_hints = {
            background = true,
          },
        },
        fidget = true,
        neotest = true,
        semantic_tokens = true,
        treesitter = true,
        which_key = true,
      },
    },
  },
  {
    -- Better messages
    'j-hui/fidget.nvim',
    opts = {
      notification = { -- Catppuccin special settings
        window = {
          winblend = 0,
        },
      },
    },
  },
  {
    -- Better statusline
    'nvim-lualine/lualine.nvim',
    opts = {
      options = {
        component_separators = '|',
        section_separators = { right = '' },
      },
    },
  },
  {
    -- Better ui elements
    'stevearc/dressing.nvim',
    opts = {
      input = {
        mappings = {
          n = {
            ['q'] = 'Close',
          },
        },
      },
    },
  },
  {
    -- Indentation guides
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
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
          'toggleterm',
          'lazyterm',
        },
      },
    },
  },
}
