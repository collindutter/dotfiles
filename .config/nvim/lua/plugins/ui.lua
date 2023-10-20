-- Plugins that change the UI of Neovim
return {
  {
    -- Tabs for buffers (sue me)
    'akinsho/bufferline.nvim',
    version = '*',
    dependencies = 'nvim-tree/nvim-web-devicons',
    event = 'BufEnter',
    opts = {},
    keys = {
      { '<leader>bo', '<cmd>BufferLineCloseOthers<cr>', desc = 'Close other buffers' },
      { '<leader>bl', '<cmd>BufferLineCloseLeft<cr>', desc = 'Close buffers to the left' },
      { '<leader>br', '<cmd>BufferLineCloseRight<cr>', desc = 'Close buffers to the right' },
      { '<leader>bb', '<cmd>BufferLinePick<cr>', desc = 'Pick buffer' },
      { '<leader>bs', '<cmd>BufferLinePick<cr>', desc = 'Sort buffer' },
      { ']b', '<cmd>BufferLineCycleNext<cr>', desc = 'Cycle next buffer' },
      { '[b', '<cmd>BufferLineCyclePrev<cr>', desc = 'Cycle prev buffer' },
    },
  },
  {
    -- Catppuccin theme
    'catppuccin/nvim',
    name = 'catppuccin',
    config = function()
      -- Don't forget to change in lazy.lua install
      vim.cmd.colorscheme 'catppuccin-macchiato'
    end,
    priority = 1000,
    lazy = false,
    opts = {
      integrations = {
        cmp = true,
        flash = true,
        gitsigns = true,
        indent_blankline = { enabled = true },
        lsp_trouble = true,
        mason = true,
        mini = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { 'undercurl' },
            hints = { 'undercurl' },
            warnings = { 'undercurl' },
            information = { 'undercurl' },
          },
        },
        neotest = true,
        noice = true,
        notify = true,
        semantic_tokens = true,
        telescope = true,
        treesitter = true,
        which_key = true,
      },
    },
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
    -- Prettier UI
    'folke/noice.nvim',
    event = 'VeryLazy',
    opts = {
      lsp = {
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
          ['cmp.entry.get_documentation'] = true,
        },
      },
      -- you can enable a preset for easier configuration
      presets = {
        bottom_search = true, -- use a classic bottom cmdline for search
        long_message_to_split = true, -- long messages will be sent to a split
        lsp_doc_border = false, -- add a border to hover docs and signature help
      },
    },
    dependencies = {
      'MunifTanjim/nui.nvim',
      'rcarriga/nvim-notify',
    },
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
}
