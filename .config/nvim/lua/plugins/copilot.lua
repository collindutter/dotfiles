return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'BufEnter',
  opts = {
    panel = { enabled = false },
    suggestion = {
      auto_trigger = true,
      debounce = 150,
    },
    filetypes = { yaml = true },
  },
}
