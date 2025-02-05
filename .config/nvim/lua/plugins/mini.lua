return {
  {
    -- Extend and create a/i textobjects
    'echasnovski/mini.ai',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    config = function()
      local spec_treesitter = require('mini.ai').gen_spec.treesitter
      require('mini.ai').setup {
        custom_textobjects = {
          f = spec_treesitter { a = '@function.outer', i = '@function.inner' },
          c = spec_treesitter { a = '@class.outer', i = '@class.inner' },
          o = spec_treesitter {
            a = { '@conditional.outer', '@loop.outer' },
            i = { '@conditional.inner', '@loop.inner' },
          },
        },
      }
    end,
  },
  {
    -- Autopairs
    'echasnovski/mini.pairs',
    opts = {},
  },
  {
    -- Surround actions
    'echasnovski/mini.surround',
    opts = {
      mappings = {
        add = 'gsa', -- Add surrounding in Normal and Visual modes
        delete = 'gsd', -- Delete surrounding
        find = '', -- Find surrounding (to the right)
        find_left = '', -- Find surrounding (to the left)
        highlight = '', -- Highlight surrounding
        replace = 'gsr', -- Replace surrounding
        update_n_lines = '', -- Update `n_lines`
      },
    },
  },
  {
    -- Go forward/backward with square brackets
    'echasnovski/mini.bracketed',
    opts = {},
  },
  {
    -- Work with diff hunks
    'echasnovski/mini.diff',
    opts = {},
  },
  {
    -- Icon provider
    'echasnovski/mini.icons',
    opts = {},
    init = function()
      require('mini.icons').mock_nvim_web_devicons()
    end,
  },
}
