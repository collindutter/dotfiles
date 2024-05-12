return {
  -- Debugger
  'mfussenegger/nvim-dap',
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Adapters
    {
      'mfussenegger/nvim-dap-python',
      config = function()
        require('dap-python').setup '~/.virtualenvs/debugpy/bin/python'
      end,
    },
  },
  config = function()
    local dap, dapui = require 'dap', require 'dapui'

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'debugpy',
      },
    }

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open

    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
    end

    dapui.setup()
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
}
