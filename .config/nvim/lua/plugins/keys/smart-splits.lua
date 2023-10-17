return {
  -- resizing splits
  {
    '<C-Left>',
    mode = 'n',
    function()
      require('smart-splits').resize_left()
    end,
    desc = 'Resize left',
  },
  {
    '<C-Down>',
    mode = 'n',
    function()
      require('smart-splits').resize_down()
    end,
    desc = 'Resize down',
  },
  {
    '<C-Up>',
    mode = 'n',
    function()
      require('smart-splits').resize_up()
    end,
    desc = 'Resize up',
  },
  {
    '<C-Right>',
    mode = 'n',
    function()
      require('smart-splits').resize_right()
    end,
    desc = 'Resize right',
  },
  -- moving between splits
  {
    '<C-h>',
    mode = 'n',
    function()
      require('smart-splits').move_cursor_left()
    end,
    desc = 'Move cursor left',
  },
  {
    '<C-j>',
    mode = 'n',
    function()
      require('smart-splits').move_cursor_down()
    end,
    desc = 'Move cursor down',
  },
  {
    '<C-k>',
    mode = 'n',
    function()
      require('smart-splits').move_cursor_up()
    end,
    desc = 'Move cursor up',
  },
  {
    '<C-l>',
    mode = 'n',
    function()
      require('smart-splits').move_cursor_right()
    end,
    desc = 'Move cursor right',
  },
}
