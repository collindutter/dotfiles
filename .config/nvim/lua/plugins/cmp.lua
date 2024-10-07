return {
  -- Autocompletion
  'hrsh7th/nvim-cmp',
  event = 'InsertEnter',
  enabled = false,
  dependencies = {
    -- LSP completion capabilities
    'hrsh7th/cmp-nvim-lsp',
    -- File paths
    'hrsh7th/cmp-path',
    -- Copilot
    'zbirenbaum/copilot.lua',
  },
  config = function()
    local cmp = require 'cmp'
    local copilot_suggestion = require 'copilot.suggestion'

    local border_opts = {
      border = 'rounded',
    }

    -- Disable the built in completion
    vim.api.nvim_set_keymap('i', '<C-n>', '<NOP>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('i', '<C-p>', '<NOP>', { noremap = true, silent = true })

    cmp.event:on('menu_closed', function()
      vim.b.copilot_suggestion_hidden = false
    end)

    cmp.setup {
      snippet = {
        expand = function(args)
          vim.snippet.expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert {
        ['<C-n>'] = cmp.mapping.select_next_item(),
        ['<C-p>'] = cmp.mapping.select_prev_item(),
        ['<C-d>'] = cmp.mapping.scroll_docs(4),
        ['<C-u>'] = cmp.mapping.scroll_docs(-4),
        ['<C-c>'] = cmp.mapping(function()
          if copilot_suggestion.is_visible() then
            copilot_suggestion.dismiss()
          end
          if cmp.visible() then
            cmp.mapping.abort()
          end
        end),
        ['<C-y>'] = cmp.mapping(function()
          if cmp.visible() then
            local entry = cmp.get_selected_entry()
            if not entry then
              cmp.select_next_item { behavior = cmp.SelectBehavior.Select }
            end
            cmp.confirm()
          end
        end),
        ['<C-l>'] = cmp.mapping(function()
          if copilot_suggestion.is_visible() then
            copilot_suggestion.accept()
          end
        end, { 'i', 's', 'c' }),
      },
      sources = cmp.config.sources {
        { name = 'nvim_lsp' },
        { name = 'path' },
        {
          { name = 'buffer' },
        },
      },
      window = {
        completion = cmp.config.window.bordered(border_opts),
        documentation = cmp.config.window.bordered(border_opts),
      },
    }
  end,
}
