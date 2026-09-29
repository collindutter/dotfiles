return {
  {
    -- Package manager
    'mason-org/mason.nvim',
    opts = {},
  },
  {
    -- Automatically install LSPs, formatters, and linters
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    opts = {
      auto_update = true,
      ensure_installed = {
        -- LSPs
        'jsonls',
        'pyright',
        'ts_ls',
        'typos_lsp',
        'yamlls',
        'lua_ls',
        'marksman',
        'html',
        'jinja_lsp',
        -- Formatters
        'prettier',
        'stylua',
        'ruff',
        'taplo',
        'shfmt',
        'djlint',
        -- Linters
        'luacheck',
        'eslint',
        'djlint',
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
