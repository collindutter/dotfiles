return {
  {
    -- Configure Lua LSP for use in Neovim
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  {
    -- Automatically enables LSPs for installed servers
    'mason-org/mason-lspconfig.nvim',
    dependencies = {
      'neovim/nvim-lspconfig',
    },
    opts = {},
  },
}
