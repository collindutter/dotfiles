return {
  -- Preserve window ratios after tmuxing
  'kwkarlwang/bufresize.nvim',
  opts = {
    register = {
      trigger_events = { 'BufWinEnter', 'WinEnter', 'WinResized' },
    },
    resize = {
      keys = {},
      trigger_events = { 'VimResized' },
      increment = false,
    },
  },
}
