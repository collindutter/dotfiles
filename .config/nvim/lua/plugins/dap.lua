return {
  {
    -- Debugger
    'mfussenegger/nvim-dap',
    dependencies = {
      {
        'igorlfs/nvim-dap-view',
        keys = {
          {
            '<leader>du',
            function()
              require('dap-view').toggle()
            end,
            desc = '[d]ebugger [u]I',
          },
        },
      },
    },
    keys = {
      {
        '<leader>ds',
        function()
          local widgets = require 'dap.ui.widgets'
          widgets.centered_float(widgets.scopes, { border = 'rounded' })
        end,
        desc = '[d]ebugger [s]copes',
      },
      {
        '<leader>dc',
        function()
          require('dap').continue()
        end,
        desc = '[d]ebugger [c]ontinue',
      },
      {
        '<leader>dl',
        function()
          require('dap').step_into()
        end,
        desc = '[d]ebugger step into',
      },
      {
        '<leader>dj',
        function()
          require('dap').step_over()
        end,
        desc = '[d]ebugger step over',
      },
      {
        '<leader>dh',
        function()
          require('dap').step_out()
        end,
        desc = '[d]ebugger step out',
      },
      {
        '<leader>db',
        function()
          require('dap').toggle_breakpoint()
        end,
        desc = '[d]ebugger [b]reakpoint',
      },
      {
        '<leader>dq',
        function()
          require('dap').close()
        end,
        desc = '[d]ebugger [q]uit',
      },
      {
        '<leader>dQ',
        function()
          require('dap').terminate()
        end,
        desc = '[d]ebugger [Q]uit',
      },
    },
    init = function()
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
