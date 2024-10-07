return {
  -- Copilot
  'zbirenbaum/copilot.lua',
  event = 'InsertEnter',
  opts = {
    panel = { enabled = false },
    suggestion = {
      auto_trigger = true,
      accept = false,
      keymap = {
        accept = '<C-l>',
      },
    },
    filetypes = {
      yaml = true,
      markdown = true,
      help = false,
      gitcommit = false,
      gitrebase = false,
      hgcommit = false,
      svn = false,
      cvs = false,
      ['grug-far'] = false,
      ['grug-far-history'] = false,
      ['grug-far-help'] = false,
      ['.'] = false,
    },
  },
}
