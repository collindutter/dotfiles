return {
  {
    '<leader>fg',
    function()
      require('telescope.builtin').git_files()
    end,
    desc = 'Find Git',
  },
  {
    '<leader>fb',
    function()
      require('telescope.builtin').buffers()
    end,
    desc = 'Find buffers',
  },
  {
    '<leader>fo',
    function()
      require('telescope.builtin').oldfiles()
    end,
    desc = 'Find old files',
  },
  {
    '<leader>ff',
    function()
      require('telescope.builtin').find_files()
    end,
    desc = 'Find files',
  },
  {
    '<leader>fh',
    function()
      require('telescope.builtin').help_tags()
    end,
    desc = 'Find help',
  },
  {
    '<leader>fc',
    function()
      require('telescope.builtin').grep_string()
    end,
    desc = 'Find current word',
  },
  {
    '<leader>fw',
    function()
      require('telescope.builtin').live_grep()
    end,
    desc = 'Find words',
  },
  {
    '<leader>fd',
    function()
      require('telescope.builtin').diagnostics()
    end,
    desc = 'Find diagnostics',
  },
  {
    '<leader>fr',
    function()
      require('telescope.builtin').resume()()
    end,
    desc = 'Find resume',
  },
  {
    '<leader>fa',
    function()
      require('telescope.builtin').find_files {

        prompt_title = 'Config Files',
        hidden = true,
        cwd = '~/.config/nvim',
      }
    end,
    desc = 'Find a config',
  },
}
