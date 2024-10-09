return {
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    opts = {
      ensure_installed = {
        -- LSPs
        'jsonls',
        'pyright',
        'ts_ls',
        'typos_lsp',
        'yamlls',
        'lua_ls',
        -- Formatters
        'prettier',
        'stylua',
        'ruff',
        -- Linters
        'luacheck',
        'eslint',
        -- Debuggers
        'debugpy',
      },
    },
  },
  {
    -- Package manager
    'williamboman/mason.nvim',
    opts = {
      ui = {
        border = 'rounded',
      },
    },
  },
}
