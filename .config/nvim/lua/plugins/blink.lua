return {
  'saghen/blink.cmp',
  -- build = 'cargo build --release',
  version = '1.*',
  enabled = true,
  opts_extend = {
    'sources.default',
  },
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer', 'codecompanion' },
      providers = {
        codecompanion = {
          name = 'CodeCompanion',
          module = 'codecompanion.providers.completion.blink',
          enabled = true,
        },
      },
    },
    appearance = {
      use_nvim_cmp_as_default = true,
      nerd_font_variant = 'mono',
    },
    keymap = { preset = 'default' },
    completion = {
      menu = {
        border = 'rounded',
      },
      documentation = {
        window = {
          border = 'rounded',
        },
        auto_show = true,
      },
    },
    signature = {
      window = {
        border = 'rounded',
      },
    },
  },
}
