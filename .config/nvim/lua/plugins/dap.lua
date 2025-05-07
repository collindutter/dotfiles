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
      {
        'theHamsta/nvim-dap-virtual-text',
        opts = {},
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
        '<leader>dK',
        function()
          local widgets = require 'dap.ui.widgets'
          widgets.hover()
        end,
        desc = '[d]ebugger hover',
      },
      {
        '<leader>df',
        function()
          local widgets = require 'dap.ui.widgets'
          widgets.centered_float(widgets.frames, { border = 'rounded' })
        end,
        desc = '[d]ebugger [f]rames',
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

      local dap = require 'dap'
      dap.adapters.debugpy = dap.adapters.python
    end,
  },
  {
    -- mason-nvim-dap doesn't register debugpy as an adapter which is required for v*code's launch.json
    --- https://github.com/mfussenegger/nvim-dap-python/issues/129
    'mfussenegger/nvim-dap-python',
    dependencies = {
      'mfussenegger/nvim-dap',
    },
    config = function()
      local mason_dir = vim.fs.joinpath(vim.fn.stdpath 'data', 'mason', 'packages')
      require('dap-python').setup(vim.fs.joinpath(mason_dir, 'debugpy', 'venv', 'bin', 'python'))
    end,
  },
}
