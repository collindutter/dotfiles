return {
    -- Move by subwords
    'chrisgrieser/nvim-spider',
    opts = { skipInsignificantPunctuation = false },
    keys = {
      {
        'w',
        function()
          require('spider').motion 'w'
        end,
        mode = { 'n', 'o', 'x' },
        desc = 'Spider-w',
      },
      {
        'e',
        function()
          require('spider').motion 'e'
        end,
        mode = { 'n', 'o', 'x' },
        desc = 'Spider-e',
      },
      {
        'b',
        function()
          require('spider').motion 'b'
        end,
        mode = { 'n', 'o', 'x' },
        desc = 'Spider-b',
      },
      {
        'ge',
        function()
          require('spider').motion 'ge'
        end,
        mode = { 'n', 'o', 'x' },
        desc = 'Spider-ge',
      },
    },
    init = function()
      vim.keymap.set({ 'n', 'o', 'x' }, 'cw', 'ce', { desc = 'Spider-ce', remap = true })
    end,
  }
