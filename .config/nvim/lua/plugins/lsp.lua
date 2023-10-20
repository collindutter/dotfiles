-- Plugins that integrate with the LSP
return {
  'neovim/nvim-lspconfig',
  dependencies = {
    -- Install LSPs to stdpath for neovim
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',

    -- Additional lua configuration
    'folke/neodev.nvim',
  },
  opts = {
    diagnostic_config = {
      virtual_text = true,
      update_in_insert = true,
      underline = true,
      severity_sort = true,
      float = {
        style = 'minimal',
        border = 'rounded',
        source = 'always',
        header = '',
        prefix = '',
      },
    },
    mason_ensure_installed = {
      'stylua',
      'luacheck',
    },
    mason_lspconfig_ensure_installed = {
      ruff_lsp = {},
      jsonls = {},
      pyright = {
        python = {
          pythonPath = '.venv/bin/python',
        },
      },
      tsserver = {},
      html = {},
      yamlls = {
        yaml = {
          customTags = {
            '!And scalar',
            '!And mapping',
            '!And sequence',
            '!If scalar',
            '!If mapping',
            '!If sequence',
            '!Not scalar',
            '!Not mapping',
            '!Not sequence',
            '!Equals scalar',
            '!Equals mapping',
            '!Equals sequence',
            '!Or scalar',
            '!Or mapping',
            '!Or sequence',
            '!FindInMap scalar',
            '!FindInMap mapping',
            '!FindInMap sequence',
            '!Base64 scalar',
            '!Base64 mapping',
            '!Base64 sequence',
            '!Cidr scalar',
            '!Cidr mapping',
            '!Cidr sequence',
            '!Ref scalar',
            '!Ref mapping',
            '!Ref sequence',
            '!Sub scalar',
            '!Sub mapping',
            '!Sub sequence',
            '!GetAtt scalar',
            '!GetAtt mapping',
            '!GetAtt sequence',
            '!GetAZs scalar',
            '!GetAZs mapping',
            '!GetAZs sequence',
            '!ImportValue scalar',
            '!ImportValue mapping',
            '!ImportValue sequence',
            '!Select scalar',
            '!Select mapping',
            '!Select sequence',
            '!Split scalar',
            '!Split mapping',
            '!Split sequence',
            '!Join scalar',
            '!Join mapping',
            '!Join sequence',
          },
        },
      },
      lua_ls = {
        Lua = {
          completion = {
            callSnippet = 'Replace',
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
    },
  },
  config = function(_, opts)
    local on_attach = function(_, bufnr)
      local lsp_map = require('helpers.keys').lsp_map

      -- Actions
      lsp_map('<leader>cr', vim.lsp.buf.rename, bufnr, 'Code rename')
      lsp_map('<leader>ca', vim.lsp.buf.code_action, bufnr, 'Code action')

      -- Diagnostics
      lsp_map('<leader>cd', vim.diagnostic.open_float, bufnr, 'Code diagnostic')
      lsp_map('[d', vim.diagnostic.goto_prev, bufnr, 'Go to previous diagnostic message')
      lsp_map(']d', vim.diagnostic.goto_next, bufnr, 'Go to next diagnostic message')

      lsp_map('gd', vim.lsp.buf.definition, bufnr, 'Goto definition')
      lsp_map('gD', vim.lsp.buf.declaration, bufnr, 'Goto declartion')
      lsp_map('gr', require('telescope.builtin').lsp_references, bufnr, 'Goto references')
      lsp_map('gI', require('telescope.builtin').lsp_implementations, bufnr, 'Goto implementation')

      -- See `:help K` for why this keymap
      lsp_map('K', vim.lsp.buf.hover, bufnr, 'Hover documentation')
      lsp_map('<leader>ch', vim.lsp.buf.signature_help, bufnr, 'Code signature help')

      -- Make diagnostics pretty
      vim.diagnostic.config(opts.diagnostic_config)
    end

    -- mason-lspconfig requires that these setup functions are called in this order
    -- before setting up the servers.
    require('mason').setup()
    local mason_lspconfig = require 'mason-lspconfig'

    local lsp_servers = opts.mason_lspconfig_ensure_installed
    mason_lspconfig.setup {
      ensure_installed = vim.tbl_keys(lsp_servers),
    }

    -- Setup neovim lua configuration
    require('neodev').setup()

    -- nvim-cmp supports additional completion capabilities, so broadcast that to servers
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

    -- Create a user command for installing all the servers
    vim.api.nvim_create_user_command('MasonInstallAll', function()
      vim.cmd('MasonInstall ' .. table.concat(opts.mason_ensure_installed, ' '))
    end, {})

    -- Ensure the servers above are installed
    mason_lspconfig.setup_handlers {
      function(server_name)
        require('lspconfig')[server_name].setup {
          capabilities = capabilities,
          on_attach = on_attach,
          settings = lsp_servers[server_name],
        }
      end,
    }
  end,
}
