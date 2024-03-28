-- Plugins that provide debugging capabilities
return {
  {
    -- DAP
    'mfussenegger/nvim-dap',
    dependencies = {
      'williamboman/mason.nvim',
      'jay-babu/mason-nvim-dap.nvim',

      'mfussenegger/nvim-dap-python',

      'rcarriga/nvim-dap-ui',
    },
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'

      dapui.setup {
        automatic_setup = true,
        handlers = {},
        ensure_installed = {
          'debugpy',
        },
      }

      dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    end,
    init = function()
      local map = require('helpers.keys').map

      map('n', '<leader>dc', function()
        require('dap').continue()
      end, '[d]ebugger [c]ontinue')

      map('n', '<leader>dl', function()
        require('dap').step_into()
      end, '[d]ebugger step into')

      map('n', '<leader>dj', function()
        require('dap').step_over()
      end, '[d]ebugger step over')

      map('n', '<leader>dh', function()
        require('dap').step_out()
      end, '[d]ebugger step out')

      map('n', '<leader>db', function()
        require('dap').toggle_breakpoint()
      end, '[d]ebugger [b]reakpoint')

      map('n', '<leader>dq', function()
        require('dap').close()
      end, '[d]ebugger [q]uit')

      map('n', '<leader>dQ', function()
        require('dap').terminate()
      end, '[d]ebugger [Q]uit')

      map('n', '<leader>du', function()
        require('dapui').toggle()
      end, '[d]ebugger [u]I')
    end,
  },
  {
    -- Python DAP adapter
    'mfussenegger/nvim-dap-python',
    config = function()
      require('dap-python').setup '~/.virtualenvs/debugpy/bin/python'
    end,
  },
  { 'rcarriga/nvim-dap-ui', dependencies = { 'mfussenegger/nvim-dap', 'nvim-neotest/nvim-nio' } },
}
