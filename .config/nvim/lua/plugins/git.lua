return {
  {
    -- Adds git related signs to the gutter
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup {
        on_attach = function(bufnr)
          local gitsigns = require 'gitsigns'

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          map('n', '<leader>gb', function()
            gitsigns.blame_line { full = true }
          end, { desc = '[g]it [blame]' })
          map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = '[t]oggle [b]lame' })
        end,
      }
    end,
  },
  {
    -- Link to the current line on GitHub
    'ruifm/gitlinker.nvim',
    requires = 'nvim-lua/plenary.nvim',
    opts = {},
    init = function()
      local map = require('helpers.keys').map

      map('n', '<leader>gy', function()
        require('gitlinker').get_repo_url()
      end, { desc = '[g]it line [y]ank' })
    end,
  },
}
