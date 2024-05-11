return {
  -- Better window resizing, navigation (integrates with tmux)
  'mrjones2014/smart-splits.nvim',
  opts = {},
  init = function()
    local map = require('helpers.keys').map

    map('n', '<C-h>', function()
      require('smart-splits').resize_left()
    end, 'Resize left')
    map('n', '<C-j>', function()
      require('smart-splits').resize_down()
    end, 'Resize down')
    map('n', '<C-k>', function()
      require('smart-splits').resize_up()
    end, 'Resize up')
    map('n', '<C-l>', function()
      require('smart-splits').resize_right()
    end, 'Resize right')
    map('n', '<C-h>', function()
      require('smart-splits').move_cursor_left()
    end, 'Move cursor left')
    map('n', '<C-j>', function()
      require('smart-splits').move_cursor_down()
    end, 'Move cursor down')
    map('n', '<C-k>', function()
      require('smart-splits').move_cursor_up()
    end, 'Move cursor up')
    map('n', '<C-l>', function()
      require('smart-splits').move_cursor_right()
    end, 'Move cursor right')
  end,
}
