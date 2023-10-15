return {
  {
    '<leader>fg',
    function()
      require('telescope.builtin').git_files()
    end,
    desc = '[f]ind [g]it',
  },
  {
    '<leader>fb',
    function()
      require('telescope.builtin').buffers()
    end,
    desc = '[f]ind [b]uffers',
  },
  {
    '<leader>fo',
    function()
      require('telescope.builtin').oldfiles()
    end,
    desc = '[f]ind [o]ld files',
  },
  {
    '<leader>ff',
    function()
      require('telescope.builtin').find_files()
    end,
    desc = '[f]ind [f]iles',
  },
  {
    '<leader>fh',
    function()
      require('telescope.builtin').help_tags()
    end,
    desc = '[f]ind [h]elp',
  },
  {
    '<leader>fc',
    function()
      require('telescope.builtin').grep_string()
    end,
    desc = '[f]ind [c]urrent word',
  },
  {
    '<leader>fw',
    function()
      require('telescope.builtin').live_grep()
    end,
    desc = '[f]ind [w]ord',
  },
  {
    '<leader>fd',
    function()
      require('telescope.builtin').diagnostics()
    end,
    desc = '[f]ind [d]iagnostics',
  },
  {
    '<leader>fr',
    function()
      require('telescope.builtin').resume()()
    end,
    desc = '[f]ind [r]esume',
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
    desc = '[f]ind [a] config',
  },
}
