return {
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
    keys = {
      { '<leader>bc', '<cmd>BufferLineCloseOthers<cr>', desc = 'Close other buffers' },
      { '<leader>bl', '<cmd>BufferLineCloseLeft<cr>', desc = 'Close buffers to the left' },
      { '<leader>br', '<cmd>BufferLineCloseRight<cr>', desc = 'Close buffers to the right' },
      { '<leader>bb', '<cmd>BufferLinePick<cr>', desc = 'Pick buffer' },
      { '<leader>bs', '<cmd>BufferLinePick<cr>', desc = 'Sort buffer' },
      { ']b', '<cmd>BufferLineCycleNext<cr>', desc = 'Cycle next buffer' },
      { '[b', '<cmd>BufferLineCyclePrev<cr>', desc = 'Cycle prev buffer' },
    },
  },
  {
    -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help ibl`
    main = 'ibl',
    event = 'BufEnter',
    opts = {},
  },
  {
    -- Catpuccin theme
    'catppuccin/nvim',
    priority = 1000,
    lazy = false,
    config = function()
      vim.cmd.colorscheme 'catppuccin-macchiato'
    end,
  },
  {
    -- Set lualine as statusline
    'nvim-lualine/lualine.nvim',
    event = 'BufEnter',
    opts = {
      options = {
        component_separators = '|',
        section_separators = { right = '' },
      },
    },
  },
}
