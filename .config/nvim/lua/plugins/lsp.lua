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
    -- Automatically enables installed LSPs, except project-selected Python checkers
    'mason-org/mason-lspconfig.nvim',
    dependencies = {
      'neovim/nvim-lspconfig',
    },
    opts = {
      automatic_enable = { exclude = require('core.python_lsp').servers },
    },
    config = function(_, opts)
      require('mason-lspconfig').setup(opts)
      require('core.python_lsp').setup()
    end,
  },
}
