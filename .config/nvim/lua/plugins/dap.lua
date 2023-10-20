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
      dap.listeners.before.event_terminated['dapui_config'] = dapui.close
      dap.listeners.before.event_exited['dapui_config'] = dapui.close
    end,
    init = function()
      local map = require("helpers.keys").map

      map('n', '<leader>dc', function()
        require('dap').continue()
      end, 'Debugger: Continue')

      map('n', '<leader>dl', function()
        require('dap').step_into()
      end, 'Debugger: Step Into')

      map('n', '<leader>dj', function()
        require('dap').step_over()
      end, 'Debugger: Step Over')

      map('n', '<leader>dh', function()
        require('dap').step_out()
      end, 'Debugger: Step Out')

      map('n', '<leader>db', function()
        require('dap').toggle_breakpoint()
      end, 'Debugger: Toggle Breakpoint')


      map('n', '<leader>dq', function()
        require('dap').close()
      end, 'Debugger: Close Session')

      map('n', '<leader>dQ', function()
        require('dap').terminate()
      end, 'Debugger: Terminate Session')

      map('n', '<leader>du', function()
        require('dapui').toggle()
      end, 'Debugger: Toggle UI')

    end,
  },
  {
    -- Python DAP adapter
    'mfussenegger/nvim-dap-python',
    config = function()
      require('dap-python').setup '~/.virtualenvs/debugpy/bin/python'
    end,
  },
}
