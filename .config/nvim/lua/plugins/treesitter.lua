-- Plugins that integrate with Treesitter
return {
  {
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    build = ':TSUpdate',
    config = function()
      vim.defer_fn(function()
        require('nvim-treesitter.configs').setup {
          ensure_installed = 'all',

          auto_install = false,
          modules = {},
          sync_install = false,
          ignore_install = {},

          highlight = { enable = true },
          indent = { enable = true },
          incremental_selection = {
            enable = true,
            keymaps = {
              node_incremental = 'v',
              node_decremental = 'V',
            },
          },
          textobjects = {
            select = {
              enable = true,
              lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
              keymaps = {
                -- You can use the capture groups defined in textobjects.scm
                ['aa'] = '@parameter.outer',
                ['ia'] = '@parameter.inner',
                ['af'] = '@function.outer',
                ['if'] = '@function.inner',
                ['ac'] = '@class.outer',
                ['ic'] = '@class.inner',
                ['ol'] = '@loop.outer',
                ['il'] = '@loop.inner',
                ['ob'] = '@block.outer',
                ['ib'] = '@block.inner',
              },
            },
            swap = {
              enable = true,
              swap_next = {
                ['<leader>a'] = '@parameter.inner',
              },
              swap_previous = {
                ['<leader>A'] = '@parameter.inner',
              },
            },
          },
        }
      end, 0)
    end,
  },
}
