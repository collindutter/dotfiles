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
    end,
  },
  {
    {
      'igorlfs/nvim-dap-view',
      opts = {},
      init = function()
        local map = require('helpers.keys').map

        map('n', '<leader>du', function()
          require('dap-view').toggle()
        end, '[d]ebugger [u]I')
      end,
    },
  },
  {
    -- Debug adapter setup
    'jay-babu/mason-nvim-dap.nvim',
    dependencies = {
      'williamboman/mason.nvim',
      'mfussenegger/nvim-dap',
    },
    opts = {
      handlers = {},
    },
  },
}
