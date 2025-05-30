return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    indent = {}, -- Indent scope
    ---@param opts? snacks.input.Opts
    --- Better input (replaces dressing.nvim)
    input = {
      win = {
        relative = 'cursor',
        row = -3,
        col = 0,
      },
    },
    -- Fuzzy picker (replaces telescope.nvim)
    picker = {
      layout = {
        preset = 'ivy',
      },
    },
    -- Image support
    image = {},
  },
  keys = {
    {
      '<leader>ff',
      function()
        Snacks.picker.smart {
          filter = {
            paths = {
              cwd = true,
            },
          },
        }
      end,
      desc = '[f]ind [f]iles',
    },
    -- Find
    {
      '<leader>fb',
      function()
        Snacks.picker.buffers()
      end,
      desc = '[f]ind [b]uffers',
    },
    -- Grep
    {
      '<leader>sg',
      function()
        Snacks.picker.grep()
      end,
      desc = '[s]earch [g]rep',
    },
    {
      '<leader>sw',
      function()
        Snacks.picker.grep_word()
      end,
      desc = '[s]earch [w]ord',
      mode = { 'n', 'x' },
    },
    -- Search
    {
      '<leader>s/',
      function()
        Snacks.picker.search_history()
      end,
      desc = '[s]earch [h]elp',
    },
    {
      '<leader>sd',
      function()
        Snacks.picker.diagnostics()
      end,
      desc = '[s]earch [d]iagnostics',
    },
    {
      '<leader>sh',
      function()
        Snacks.picker.help()
      end,
      desc = '[s]earch [h]elp',
    },
    {
      '<leader>sk',
      function()
        Snacks.picker.keymaps()
      end,
      desc = '[s]earch [k]eymaps',
    },
    {
      '<leader>sq',
      function()
        Snacks.picker.qflist()
      end,
      desc = '[s]earch [q]uickfix',
    },
    {
      '<leader>sR',
      function()
        Snacks.picker.resume()
      end,
      desc = '[s]earch [R]esume',
    },
    -- LSP
    {
      'gd',
      function()
        Snacks.picker.lsp_definitions()
      end,
      desc = '[g]oto [d]efinition',
    },
    {
      'gD',
      function()
        Snacks.picker.lsp_declarations()
      end,
      desc = '[g]oto [D]eclaration',
    },
    {
      'grr',
      function()
        Snacks.picker.lsp_references()
      end,
      nowait = true,
      desc = '[g]oto [r]eferences',
    },
    {
      'gri',
      function()
        Snacks.picker.lsp_implementations()
      end,
      desc = '[g]oto [i]mplementations',
    },
    -- Buffer delete
    {
      '<leader>bd',
      function()
        require('snacks').bufdelete()
      end,
      desc = '[b]uffer [d]elete',
    },
    {
      '<leader>bo',
      function()
        require('snacks').bufdelete.other()
      end,
      desc = '[b]uffer delete [o]thers',
    },
  },
}
