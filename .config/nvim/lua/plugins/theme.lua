return {
  -- Catppuccin theme
  'catppuccin/nvim',
  name = 'catppuccin',
  priority = 1000,
  init = function()
    vim.cmd.colorscheme 'catppuccin-macchiato'
  end,
  opts = {
    flavour = 'macchiato',
    transparent_background = true,
    styles = {
      comments = {},
      conditionals = {},
    },
    integrations = {
      cmp = true,
      dap = {
        enabled = true,
        enable_ui = true,
      },
      flash = true,
      gitsigns = true,
      indent_blankline = { enabled = true },
      lsp_trouble = true,
      mason = true,
      native_lsp = {
        enabled = true,
        virtual_text = {
          errors = { 'italic' },
          hints = { 'italic' },
          warnings = { 'italic' },
          information = { 'italic' },
        },
        underlines = {
          errors = { 'undercurl' },
          hints = { 'undercurl' },
          warnings = { 'undercurl' },
          information = { 'undercurl' },
        },
        inlay_hints = {
          background = true,
        },
      },
      fidget = true,
      neotest = true,
      semantic_tokens = true,
      treesitter = true,
      which_key = true,
    },
  },
}
