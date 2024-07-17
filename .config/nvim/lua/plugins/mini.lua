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
    -- Remove buffers
    'echasnovski/mini.bufremove',
    opts = {},
    init = function()
      local map = require('helpers.keys').map

      map('n', '<leader>bc', function()
        require('mini.bufremove').delete(0, true)
      end, '[b]uffer [c]lose')

      map('n', '<leader>bo', function()
        local bufremove = require 'mini.bufremove'
        local buflist = vim.api.nvim_list_bufs()
        local curbufnr = vim.api.nvim_get_current_buf()

        for _, bufnr in ipairs(buflist) do
          if vim.bo[bufnr].buflisted and bufnr ~= curbufnr and (vim.fn.getbufvar(bufnr, 'bufpersist') ~= 1) then
            bufremove.delete(bufnr, true)
          end
        end
      end, '[b]uffer close [o]thers')
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
        add = "gsa",    -- Add surrounding in Normal and Visual modes
        delete = "gsd", -- Delete surrounding
      }
    },
  },
  {
    -- Go forward/backward with square brackets
    'echasnovski/mini.bracketed',
    opts = {},
  },
  {
    -- Show indent scope, also adds Treesitter object `i` (i.e. `yai` `dii`).
    'echasnovski/mini.indentscope',
    opts = {},
  },
  {
    -- Notifications
    'echasnovski/mini.notify',
    opts = {
      window = {
        config = {
          border = 'rounded',
        },
        winblend = 0,
      },
    },
  },
  {
    -- Work with diff hunks
    'echasnovski/mini.diff',
    opts = {}
  },
  {
    -- Statusline
    'echasnovski/mini.statusline',
    opts = {
      set_vim_settings = false,
    }
  },
  {
    -- Icon provider
    "echasnovski/mini.icons",
    opts = {},
    specs = { { "nvim-tree/nvim-web-devicons", enabled = false, optional = true } },
    init = function()                                   -- https://old.reddit.com/r/neovim/comments/1duf3w7/miniicons_general_icon_provider_several/lbgbc6a/
      package.preload["nvim-web-devicons"] = function() -- needed since it will be false when loading and mini will fail
        package.loaded["nvim-web-devicons"] = {}
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
  },
}
