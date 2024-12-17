return {
  'saghen/blink.cmp',
  -- build = 'cargo build --release',
  version = 'v0.*',
  enabled = true,
  opts_extend = { 'sources.completion.enabled_providers' },
  opts = {
    sources = {
      completion = {
        enabled_providers = { 'lsp', 'path', 'snippets', 'buffer', 'codecompanion' },
      },
      providers = {
        codecompanion = {
          name = 'CodeCompanion',
          module = 'codecompanion.providers.completion.blink',
          enabled = true,
        },
      },
    },
    highlight = {
      use_nvim_cmp_as_default = true,
    },
    nerd_font_variant = 'normal',
    keymap = { preset = 'default' },
    completion = {
      menu = {
        border = 'rounded',
      },
      signature = {
        window = {
          border = 'rounded',
        },
      },
      documentation = {
        window = {
          border = 'rounded',
        },
        auto_show = true,
      },
    },
  },
}
