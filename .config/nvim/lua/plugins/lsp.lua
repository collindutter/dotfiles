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
    -- Bridges the gap between Mason and LSP
    'mason-org/mason-lspconfig.nvim',
    dependencies = {
      'neovim/nvim-lspconfig',
    },
    opts = {
      ensure_installed = {},
      automatic_installation = false,
      handlers = {
        function(name)
          vim.lsp.enable(name)
        end,
      },
    },
  },
}
