return function(_, opts)
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

    -- Make lsp windows pretty
    vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, {
      border = 'rounded',
    })

    vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, {
      border = 'rounded',
    })
  end

  -- mason-lspconfig requires that these setup functions are called in this order
  -- before setting up the servers.
  require('mason').setup()
  local mason_lspconfig = require 'mason-lspconfig'

  local lsp_servers = opts.mason_lspconfig_ensure_installed
  mason_lspconfig.setup {
    ensure_installed = vim.tbl_keys(lsp_servers)
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
        filetypes = (lsp_servers[server_name] or {}).filetypes,
      }
    end,
  }
end
