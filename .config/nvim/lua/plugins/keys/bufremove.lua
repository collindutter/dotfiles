return {
  {
    '<leader>bc',
    function()
      require('mini.bufremove').delete(0, false)
    end,
    desc = 'Buffer close',
  },
  {
    '<leader>bC',
    function()
      require('mini.bufremove').delete(0, true)
    end,
    desc = 'Buffer force close',
  },
}
