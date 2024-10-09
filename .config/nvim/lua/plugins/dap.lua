return {
  {
    -- Debugger
    'mfussenegger/nvim-dap',
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
    -- Debugger UI
    'rcarriga/nvim-dap-ui',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'mfussenegger/nvim-dap',
    },
    config = function()
      local dap, dapui = require 'dap', require 'dapui'

      -- Make UI pretty
      local signs = {
        ['DapBreakpoint'] = '',
        ['DapBreakpointCondition'] = '',
        ['DapBreakpointRejected'] = '',
        ['DapLogPoint'] = '.>',
        ['DapStopped'] = '󰁕',
      }

      for type, icon in pairs(signs) do
        vim.fn.sign_define(type, { text = icon, texthl = type, numhl = type })
      end

      -- Set up listeners on the UI
      dap.listeners.after.event_initialized['dapui_config'] = dapui.open
      dap.listeners.before.attach.dapui_config = dapui.open
      dap.listeners.before.launch.dapui_config = dapui.open

      dapui.setup()
    end,
  },
  {
    -- Debug adapter setup
    'jay-babu/mason-nvim-dap.nvim',
    dependencies = {
      'williamboman/mason.nvim',
      'mfussenegger/nvim-dap',
    },
    opts = {
      handlers = {
        python = function() end,
      },
    },
  },
  {
    -- mason-nvim-dap messes up python setup somehow so we need to manually set it up
    -- https://github.com/mfussenegger/nvim-dap-python/issues/146
    'mfussenegger/nvim-dap-python',
    dependencies = {
      'mfussenegger/nvim-dap',
    },
    config = function()
      require('dap-python').setup '/Users/collindutter/.local/share/nvim/mason/packages/debugpy/venv/bin/python'
    end,
  },
}
