return {
  {
    -- Surround motions
    'kylechui/nvim-surround',
    opts = {},
  },
  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    config = function()
      -- Better Around/Inside textobjects
      require('mini.ai').setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      require('mini.surround').setup()

      -- Commenting
      require('mini.comment').setup()

      -- Simple and easy statusline.
      require('mini.statusline').setup { use_icons = true }
    end,
  },
  {
    -- Autocompletion
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      -- LSP completion capabilities
      'hrsh7th/cmp-nvim-lsp',
      -- File paths
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-cmdline',
      -- Snippet Engine & its associated nvim-cmp source
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
      -- Copilot
      'zbirenbaum/copilot.lua',
    },
    config = function() end,
  },
  {
    -- Copilot
    -- TODO When copilot loads it makes lualine disappear until you type something. Ideally we'd lazy load it, but cmp does not lazy load.
    'zbirenbaum/copilot.lua',
    event = 'InsertEnter',
    opts = {
      panel = { enabled = false },
      suggestion = {
        auto_trigger = true,
        accept = false,
      },
      filetypes = { yaml = true, markdown = true, help = true },
    },
  },
  {
    -- Autopair quotes, brackets, etc
    'windwp/nvim-autopairs',
    opts = {},
  },
}
