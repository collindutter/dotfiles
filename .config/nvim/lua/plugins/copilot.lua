return {
  -- Copilot
  'zbirenbaum/copilot.lua',
  event = 'InsertEnter',
  opts = {
    panel = { enabled = false },
    suggestion = {
      auto_trigger = true,
      accept = false,
    },
    filetypes = { yaml = true, markdown = true, help = false },
  },
}
