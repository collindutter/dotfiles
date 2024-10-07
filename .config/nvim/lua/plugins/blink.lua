return {
  'saghen/blink.cmp',
  version = 'v0.*',
  opts = {
    highlight = {
      use_nvim_cmp_as_default = true,
    },
    nerd_font_variant = 'normal',

    keymap = {
      show = '<C-space>',
      hide = '<C-e>',
      accept = '<C-y>',
      select_prev = { '<C-p>' },
      select_next = { '<C-n>' },

      show_documentation = {},
      hide_documentation = {},
      scroll_documentation_up = '<C-u>',
      scroll_documentation_down = '<C-d>',

      snippet_forward = '<Tab>',
      snippet_backward = '<S-Tab>',
    },
    windows = {
      autocomplete = {
        border = 'rounded',
      },
      signature_help = {
        border = 'rounded',
      },
      documentation = {
        border = 'rounded',
      },
    },
  },
}
