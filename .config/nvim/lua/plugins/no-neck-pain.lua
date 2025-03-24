return {
  'shortcuts/no-neck-pain.nvim',
  opts = {
    width = 150,
  },
  keys = {
    {
      '<leader>un',
      function()
        require('no-neck-pain').toggle()
      end,
      desc = '[u]I [n]eck pain',
    },
  },
}
