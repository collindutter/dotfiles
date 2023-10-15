-- Highlight on yank
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight on yank',
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- Better close
vim.api.nvim_create_autocmd('BufWinEnter', {
  desc = 'Make q close help, man, quickfix, dap floats',
  group = vim.api.nvim_create_augroup('q_close_windows', { clear = true }),
  callback = function(args)
    local buftype = vim.api.nvim_get_option_value('buftype', { buf = args.buf })
    if vim.tbl_contains({ 'help', 'nofile', 'quickfix' }, buftype) and vim.fn.maparg('q', 'n') == '' then
      vim.keymap.set('n', 'q', '<cmd>close<cr>', {
        desc = 'Close window',
        buffer = args.buf,
        silent = true,
        nowait = true,
      })
    end
  end,
})

-- Restore cursor position
vim.api.nvim_create_autocmd('BufRead', {
  desc = 'Restore cursor position',
  callback = function(opts)
    vim.api.nvim_create_autocmd('BufWinEnter', {
      once = true,
      buffer = opts.buf,
      callback = function()
        local ft = vim.bo[opts.buf].filetype
        local last_known_line = vim.api.nvim_buf_get_mark(opts.buf, '"')[1]
        if not (ft:match 'commit' and ft:match 'rebase') and last_known_line > 1 and last_known_line <= vim.api.nvim_buf_line_count(opts.buf) then
          vim.api.nvim_feedkeys([[g`"]], 'nx', false)
        end
      end,
    })
  end,
})
