return {
  'ibhagwan/fzf-lua',
  -- optional for icon support
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    local actions = require 'fzf-lua.actions'

    require('fzf-lua').setup {
      keymap = {
        builtin = {
          ['<C-d>'] = 'preview-page-down',
          ['<C-u>'] = 'preview-page-up',
        },
        fzf = {
          -- fzf '--bind=' options
          ['ctrl-c'] = 'abort',
        },
      },
      actions = {
        files = {
          -- Note this keymap syntax uses fzf
          ['default'] = actions.file_edit_or_qf,
          ['ctrl-q'] = actions.file_sel_to_qf,
          ['ctrl-l'] = actions.file_sel_to_ll,
        },
      },
      hls = {
        border = 'FloatBorder',
        preview_border = 'FloatBorder',
      },
      files = {
        cwd_prompt = false,
      },
    }
  end,
  init = function()
    local map = require('helpers.keys').map

    map('n', '<leader>fg', function()
      require('fzf-lua').git_files()
    end, '[f]ind [g]it files')
    map('n', '<leader>fb', function()
      require('fzf-lua').buffers()
    end, '[f]ind [b]uffers')
    map('n', '<leader>fo', function()
      require('fzf-lua').oldfiles()
    end, '[f]ind [o]ld files')
    map('n', '<leader>ff', function()
      require('fzf-lua').files()
    end, '[f]ind [f]iles')
    map('n', '<leader>fh', function()
      require('fzf-lua').help_tags()
    end, '[f]ind [h]elp')
    map('n', '<leader>fc', function()
      require('fzf-lua').grep_string()
    end, '[f]ind [c]current word')
    map('n', '<leader>fv', function()
      require('fzf-lua').grep_visual()
    end, '[f]ind [v]isual selection')
    map('n', '<leader>fw', function()
      require('fzf-lua').live_grep()
    end, '[f]ind [w]ord')
    map('n', '<leader>fg', function()
      require('fzf-lua').live_grep { cmd = 'git grep --line-number --column --color=always', prompt = 'Git History>' }
    end, '[f]ind [g]it history')
    map('n', '<leader>fd', function()
      require('fzf-lua').diagnostics()
    end, '[f]ind [d]iagnostics')
    map('n', '<leader>fr', function()
      require('fzf-lua').resume()
    end, '[f]ind [r]esume')
    map('n', '<leader>fa', function()
      require('fzf-lua').files {
        prompt = 'Config>',
        hidden = true,
        cwd = '~/.config/nvim',
      }
    end, '[f]ind [a]ll config files')
    map('n', '<leader>fh', function()
      require('fzf-lua').files {
        prompt = 'Hidden>',
        no_ignore = true,
        hidden = true,
      }
    end, '[f]ind [h]idden')
  end,
}
