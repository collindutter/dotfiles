return {
  -- Highlight, edit, and navigate code
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  opts = {
    ensure_installed = 'all',
    auto_install = true,
    highlight = {
      enable = true,
    },
    indent = { enable = false },
  },
  config = function(_, opts)
    require('nvim-treesitter.configs').setup(opts)
  end,
}
