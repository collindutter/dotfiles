return {
  {
    -- Package manager
    'williamboman/mason.nvim',
    opts = {
      ui = {
        border = 'rounded',
      },
    },
  },
  {
    -- Automatically install LSPs, formatters, linters, and debuggers
    -- This is a better, consolidated version of the ensure_installed functionality in mason-lspconfig.nvim and mason-nvim-dap.nvim
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    opts = {
      auto_update = true,
      ensure_installed = {
        -- LSPs
        'jsonls',
        'pyright',
        'basedpyright',
        'ts_ls',
        'typos_lsp',
        'yamlls',
        'lua_ls',
        'angularls',
        'marksman',
        'html',
        'jinja_lsp',
        -- Formatters
        'prettier',
        'stylua',
        'ruff',
        'taplo',
        'shfmt',
        -- Linters
        'luacheck',
        'eslint',
        'djlint',
        -- Debuggers
        'debugpy',
      },
    },
    init = function()
      vim.filetype.add {
        extension = {
          jinja = 'jinja',
          jinja2 = 'jinja',
          j2 = 'jinja',
        },
      }
    end,
  },
}
