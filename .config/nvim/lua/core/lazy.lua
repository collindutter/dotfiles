-- Install lazy.nvim if not already installed
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

-- Use a protected call so we don't error out on first use
local ok, lazy = pcall(require, 'lazy')
if not ok then
  return
end

-- Set leader
local leader_key = ' '
vim.g.mapleader = leader_key
vim.g.maplocalleader = leader_key
vim.keymap.set({ 'n', 'v' }, leader_key, '<nop>', { silent = true })

-- Load plugins from specifications
-- (The leader key must be set before this)
lazy.setup('plugins', {
  ui = {
    border = 'rounded',
  },
  change_detection = {
    notify = false,
  },
  defaults = {
    lazy = false,
  },
  install = {
    colorscheme = { 'catppuccin-macchiato' },
  },
})

-- Might as well set up an easy-access keybinding
require('helpers.keys').map('n', '<leader>L', lazy.show, 'Show [L]azy')
require('helpers.keys').map('n', '<leader>R', '<cmd>Lazy reload griptape.nvim<cr>', '[R]eload Griptape')
