return {
  { '<leader>bc', '<cmd>BufferLineCloseOthers<cr>', desc = 'Close other buffers' },
  { '<leader>bl', '<cmd>BufferLineCloseLeft<cr>', desc = 'Close buffers to the left' },
  { '<leader>br', '<cmd>BufferLineCloseRight<cr>', desc = 'Close buffers to the right' },
  { '<leader>bb', '<cmd>BufferLinePick<cr>', desc = 'Pick buffer' },
  { '<leader>bs', '<cmd>BufferLinePick<cr>', desc = 'Sort buffer' },
  { ']b', '<cmd>BufferLineCycleNext<cr>', desc = 'Cycle next buffer' },
  { '[b', '<cmd>BufferLineCyclePrev<cr>', desc = 'Cycle prev buffer' },
}
