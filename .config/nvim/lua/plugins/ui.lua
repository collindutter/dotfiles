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
        neotest = true,
        noice = true,
        semantic_tokens = true,
        treesitter = true,
        which_key = true,
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
    config = function(_, opts)
      require('lualine').setup(vim.tbl_deep_extend('force', opts, {
        sections = {
          lualine_x = {
            {
              require('noice').api.statusline.mode.get,
              cond = require('noice').api.statusline.mode.has,
              color = { fg = '#ff9e64' },
            },
          },
        },
      }))
    end,
  },
  {
    -- Prettier UI
    'folke/noice.nvim',
    opts = {
      lsp = {
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
          ['cmp.entry.get_documentation'] = true,
        },
      },
      presets = {
        bottom_search = true, -- use a classic bottom cmdline for search
        long_message_to_split = true, -- long messages will be sent to a split
        lsp_doc_border = true, -- add a border to hover docs and signature help
      },
    },
    dependencies = {
      'MunifTanjim/nui.nvim',
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
