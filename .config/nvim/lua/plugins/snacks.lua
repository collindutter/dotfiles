return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    indent = {}, -- Indent scope
  },
  keys = {
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
