return {
  -- Autocompletion
  'hrsh7th/nvim-cmp',
  event = 'InsertEnter',
  dependencies = {
    -- LSP completion capabilities
    'hrsh7th/cmp-nvim-lsp',
    -- File paths
    'hrsh7th/cmp-path',
    'hrsh7th/cmp-cmdline',
    -- Snippet Engine & its associated nvim-cmp source
    'L3MON4D3/LuaSnip',
    'saadparwaiz1/cmp_luasnip',
    -- Copilot
    'zbirenbaum/copilot.lua',
  },
  config = function()
    local cmp = require 'cmp'
    local copilot_suggestion = require 'copilot.suggestion'
    local luasnip = require 'luasnip'

    luasnip.config.setup {}

    local border_opts = {
      border = 'rounded',
    }

    cmp.event:on('menu_closed', function()
      ---@diagnostic disable-next-line: inject-field
      vim.b.copilot_suggestion_hidden = false
    end)

    cmp.setup {
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert {
        ['<C-n>'] = cmp.mapping.select_next_item(),
        ['<C-p>'] = cmp.mapping.select_prev_item(),
        ['<C-d>'] = cmp.mapping.scroll_docs(-4),
        ['<C-u>'] = cmp.mapping.scroll_docs(4),
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
          elseif luasnip.expand_or_locally_jumpable() then
            luasnip.expand_or_jump()
          end
        end, { 'i', 's', 'c' }),
      },
      sources = cmp.config.sources {
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
        { name = 'path' },
      },
      window = {
        completion = cmp.config.window.bordered(border_opts),
        documentation = cmp.config.window.bordered(border_opts),
      },
    }

    cmp.setup.cmdline(':', {
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({
        { name = 'path' },
      }, {
        { name = 'cmdline' },
      }),
    })
  end,
}
