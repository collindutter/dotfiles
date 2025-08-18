return {
  -- Catppuccin theme
  'catppuccin/nvim',
  name = 'catppuccin',
  priority = 1000,
  init = function()
    vim.cmd.colorscheme 'catppuccin'
  end,
  opts = {
    transparent_background = true, -- disables setting the background color.
    float = {
      transparent = true, -- enable transparent floating windows
    },
    styles = {
      comments = {}, -- by default it's italic
      conditionals = {}, -- by default it's italic
    },
    integrations = {

      dap = true,
      dap_ui = true,
      flash = true,
      mason = true,
      blink_cmp = true,
      mini = {
        enabled = true,
      },
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
      neotest = true,
      semantic_tokens = true,
      treesitter = true,
      which_key = true,
      telescope = {
        enabled = true,
      },
    },
  },
}
