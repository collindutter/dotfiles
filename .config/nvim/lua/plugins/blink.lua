return {
  'saghen/blink.cmp',
  -- build = 'cargo build --release',
  version = 'v0.*',
  enabled = true,
  opts = {
    highlight = {
      use_nvim_cmp_as_default = true,
    },
    nerd_font_variant = 'normal',
    keymap = 'default',
    windows = {
      autocomplete = {
        border = 'rounded',
      },
      signature_help = {
        border = 'rounded',
      },
      documentation = {
        border = 'rounded',
        auto_show = true,
      },
    },
  },
}
