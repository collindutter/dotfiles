-- Plugins that provide debugging capabilities
return {
  {
    -- DAP
    'mfussenegger/nvim-dap',
    dependencies = {
      'williamboman/mason.nvim',
      'jay-babu/mason-nvim-dap.nvim',

      'mfussenegger/nvim-dap-python',
    },
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'

      dapui.setup()

      dap.listeners.after.event_initialized['dapui_config'] = dapui.open
      dap.listeners.before.event_terminated['dapui_config'] = dapui.close
      dap.listeners.before.event_exited['dapui_config'] = dapui.close
    end,
    keys = {
      {
        '<leader>dc',
        function()
          require('dap').continue()
        end,
        desc = 'Debugger: Continue',
      },
      {
        '<leader>dl',
        function()
          require('dap').step_into()
        end,
        desc = 'Debugger: Step Into',
      },
      {
        '<leader>dj',
        function()
          require('dap').step_over()
        end,
        desc = 'Debugger: Step Over',
      },
      {
        '<leader>dh',
        function()
          require('dap').step_out()
        end,
        desc = 'Debugger: Step Out',
      },
      {
        '<leader>db',
        function()
          require('dap').toggle_breakpoint()
        end,
        desc = 'Debugger: Toggle Breakpoint',
      },
      {
        '<leader>dq',
        function()
          require('dap').close()
        end,
        desc = 'Debugger: Close Session',
      },
      {
        '<leader>dQ',
        function()
          require('dap').terminate()
        end,
        desc = 'Debugger: Terminate Session',
      },
      {
        '<leader>du',
        function()
          require('dapui').toggle()
        end,
        desc = 'Debugger: Toggle UI',
      },
    },
  },
  {
    -- DAP UI
    'rcarriga/nvim-dap-ui',
    opts = {
      automatic_setup = true,
      handlers = {},
      ensure_installed = {
        'debugpy',
      },
    },
  },
  {
    -- Python DAP adapter
    'mfussenegger/nvim-dap-python',
    config = function()
      require('dap-python').setup '~/.virtualenvs/debugpy/bin/python'
    end,
  },
}
