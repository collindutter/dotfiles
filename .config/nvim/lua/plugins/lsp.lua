return {
  -- LSP Configuration & Plugins
  'neovim/nvim-lspconfig',
  event = 'BufEnter',
  dependencies = {
    -- Automatically install LSPs to stdpath for neovim
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',

    -- Useful status updates for LSP
    { 'j-hui/fidget.nvim', tag = 'legacy', opts = {} },

    -- Additional lua configuration, makes nvim stuff amazing!
    'folke/neodev.nvim',
  },
  config = function()
    -- [[ LSP ]]
    local on_attach = function(_, bufnr)
      local lsp_map = require('helpers.keys').lsp_map
      lsp_map('<leader>lr', vim.lsp.buf.rename, bufnr, 'Rename current symbol')
      lsp_map('<leader>la', vim.lsp.buf.code_action, bufnr, 'Code action')

      -- Diagnostics
      lsp_map('<leader>ld', vim.diagnostic.open_float, bufnr, 'Hover diagnostic')
      lsp_map('[d', vim.diagnostic.goto_prev, bufnr, 'Go to previous diagnostic message')
      lsp_map(']d', vim.diagnostic.goto_next, bufnr, 'Go to next diagnostic message')

      lsp_map('gd', vim.lsp.buf.definition, bufnr, 'Goto definition')
      lsp_map('gD', vim.lsp.buf.declaration, bufnr, 'Goto declartion')
      lsp_map('gr', require('telescope.builtin').lsp_references, bufnr, 'Goto references')
      lsp_map('gI', require('telescope.builtin').lsp_implementations, bufnr, 'Goto implementation')

      -- See `:help K` for why this keymap
      lsp_map('K', vim.lsp.buf.hover, bufnr, 'Hover documentation')
      lsp_map('<leader>lh', vim.lsp.buf.signature_help, bufnr, 'Signature help')
    end

    -- mason-lspconfig requires that these setup functions are called in this order
    -- before setting up the servers.
    require('mason').setup()
    require('mason-lspconfig').setup()

    local lsp_servers = {
      ruff_lsp = {},
      jsonls = {},
      pyright = {
        python = {
          pythonPath = '.venv/bin/python',
        },
      },
      tsserver = {},
      html = {},
      lua_ls = {
        Lua = {
          telemetry = { enable = false },
          completion = {
            callSnippet = 'Replace',
          },
          diagnostics = {
            globals = { 'vim' },
          },
          workspace = {
            checkThirdParty = false,
            library = {
              [vim.fn.expand '$VIMRUNTIME/lua'] = true,
              [vim.fn.stdpath 'config' .. '/lua'] = true,
            },
          },
        },
      },
    }

    -- Setup neovim lua configuration
    require('neodev').setup()

    -- nvim-cmp supports additional completion capabilities, so broadcast that to servers
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

    -- Ensure the servers above are installed
    local mason_lspconfig = require 'mason-lspconfig'

    mason_lspconfig.setup {
      ensure_installed = vim.tbl_keys(lsp_servers),
    }

    local options = {
      ensure_installed = { 'stylua', 'luacheck' },
    }
    require('mason').setup(options)
    vim.api.nvim_create_user_command('MasonInstallAll', function()
      vim.cmd('MasonInstall ' .. table.concat(options.ensure_installed, ' '))
    end, {})

    mason_lspconfig.setup_handlers {
      function(server_name)
        require('lspconfig')[server_name].setup {
          capabilities = capabilities,
          on_attach = on_attach,
          settings = lsp_servers[server_name],
          filetypes = (lsp_servers[server_name] or {}).filetypes,
        }
      end,
    }
  end,
}
