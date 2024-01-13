---@diagnostic disable: missing-fields
---@diagnostic disable: inject-field
-- Plugins that impact typing code
return {
  {
    -- Surround motions
    'kylechui/nvim-surround',
    opts = {},
  },
  {
    -- Comment visual regions/lines
    'numToStr/Comment.nvim',
    opts = {},
  },
  {
    -- Move by subwords
    'chrisgrieser/nvim-spider',
    opts = { skipInsignificantPunctuation = false },
    init = function()
      local map = require('helpers.keys').map

      map({ 'n', 'o', 'x' }, 'w', function()
        require('spider').motion 'w'
      end, 'Spider w')

      map({ 'n', 'o', 'x' }, 'e', function()
        require('spider').motion 'e'
      end, 'Spider e')

      map({ 'n', 'o', 'x' }, 'b', function()
        require('spider').motion 'b'
      end, 'Spider b')
      map({ 'n', 'o', 'x' }, 'ge', function()
        require('spider').motion 'ge'
      end, 'Spider ge')

      vim.keymap.set({ 'n', 'o', 'x' }, 'cw', 'ce', { desc = 'Spider-ce', remap = true })
    end,
  },
  {
    -- Easy motion
    'folke/flash.nvim',
    opts = { modes = { search = { enabled = false } } },
    init = function()
      local map = require('helpers.keys').map

      map({ 'n', 'o', 'x' }, 's', function()
        require('flash').jump()
      end, 'Flash')

      map({ 'n', 'o', 'x' }, 'S', function()
        require('flash').treesitter()
      end, 'Flash Treesitter')
    end,
  },
  {
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
      require('luasnip.loaders.from_vscode').lazy_load()

      luasnip.config.setup {}

      local border_opts = {
        border = 'rounded',
      }

      cmp.event:on('menu_closed', function()
        vim.b.copilot_suggestion_hidden = false
      end)

      cmp.setup {
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert {
          ['<C-n>'] = cmp.mapping(function()
            cmp.select_next_item()
            vim.b.copilot_suggestion_hidden = true
          end),
          ['<C-p>'] = cmp.mapping(function()
            cmp.select_prev_item()
            vim.b.copilot_suggestion_hidden = true
          end),
          ['<C-d>'] = cmp.mapping.scroll_docs(-4),
          ['<C-u>'] = cmp.mapping.scroll_docs(4),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<C-c>'] = cmp.mapping(function()
            if copilot_suggestion.is_visible() then
              copilot_suggestion.dismiss()
            end
          end),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if copilot_suggestion.is_visible() then
              copilot_suggestion.accept()
            elseif cmp.visible() then
              local entry = cmp.get_selected_entry()

              if not entry then
                cmp.select_next_item { behavior = cmp.SelectBehavior.Select }
              else
                cmp.confirm()
              end
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
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
  },
  {
    -- Copilot
    -- TODO When copilot loads it makes lualine disappear until you type something. Ideally we'd lazy load it, but cmp does not lazy load.
    'zbirenbaum/copilot.lua',
    event = 'InsertEnter',
    opts = {
      panel = { enabled = false },
      suggestion = {
        auto_trigger = true,
        accept = false,
      },
      filetypes = { yaml = true, markdown = true, help = true },
    },
  },
  {
    -- Autopair quotes, brackets, etc
    'windwp/nvim-autopairs',
    opts = {},
  },
  {
    -- Make life hell
    'm4xshen/hardtime.nvim',
    dependencies = { 'MunifTanjim/nui.nvim', 'nvim-lua/plenary.nvim' },
    opts = {
      disabled_filetypes = {
        'lazy',
        'mason',
        'neo-tree',
        'neo-tree-popup',
        'dapui_breakpoints',
        'dapui_scopes',
        'dapui_stacks',
        'dapui_watches',
        'dapui_console',
        'dap-repl',
        'dap-float',
        'alpha',
        'noice',
        'vim',
        'qf',
        'dressinginput',
        'TelescopePrompt',
        'trouble',
        'help',
        'spectre_panel',
        'oil',
      },
    },
  },
  {
    -- AI debugging
    'piersolenski/wtf.nvim',
    dependencies = {
      'MunifTanjim/nui.nvim',
    },
    opts = {},
    init = function()
      local map = require('helpers.keys').map

      map({ 'n', 'x' }, '<leader>cw', function()
        require('wtf').ai()
      end, 'Wtf Ai')
      map({ 'n', 'x' }, '<leader>cW', function()
        require('wtf').search()
      end, 'Wtf Google')
    end,
  },
}
