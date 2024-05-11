return {
  -- Better messages
  'j-hui/fidget.nvim',
  opts = {
    progress = {
      display = {
        done_icon = "✓", -- For some reason the build-in icon doesn't work
      }
    },
    notification = { -- Make the window transparent with Catppuccin
      window = {
        winblend = 0,
      },
    },
  },
}
