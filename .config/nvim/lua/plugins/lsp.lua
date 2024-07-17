return {
  'neovim/nvim-lspconfig',
  dependencies = {
    -- Install LSPs to stdpath for neovim
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',

    -- Additional lua configuration
    {
      "folke/lazydev.nvim",
      ft = "lua", -- only load on lua files
      opts = {},
    },
  },
  opts = {
    ui = {
      diagnostic_config = {
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = '',
            [vim.diagnostic.severity.WARN] = '',
            [vim.diagnostic.severity.HINT] = '󰌵',
            [vim.diagnostic.severity.INFO] = '󰋼',
          },
        },
        severity_sort = true,
        float = {
          border = 'rounded',
        },
      },
      float = {
        border = 'rounded',
      },
    },
    --  Available keys are:
    --  - cmd (table): Override the default command used to start the server
    --  - filetypes (table): Override the default list of associated filetypes for the server
    --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
    --  - settings (table): Override the default settings passed when initializing the server.
    --  For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
    servers = {
      jsonls = {},
      basedpyright = {
        settings = {
          basedpyright = {
            analysis = {
              venvPath = ".",
              venv = ".venv",
              typeCheckingMode = 'standard',
              autoSearchPaths = true,
              diagnosticMode = "openFilesOnly",
              useLibraryCodeForTypes = true,

              -- Using Ruff's import organizer
              disableOrganizeImports = true
            },
          },
          python = {
            analysis = {
              -- Ignore all files for analysis to exclusively use Ruff for linting
              ignore = { '*' },
            },
          }
        },
      },
      ruff = {},
      tsserver = {},
      html = {},
      typos_lsp = {},
      yamlls = {
        settings = {
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
        }
      },
      lua_ls = {
        settings = {
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
        }
      },
    },
  },
  config = function(_, opts)
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
      callback = function(event)
        local function lsp_map(lhs, rhs, desc)
          vim.keymap.set('n', lhs, rhs, { buffer = event.buf, desc = desc })
        end

        -- Actions
        lsp_map('<leader>cr', vim.lsp.buf.rename, '[c]ode [r]ename')
        lsp_map('<leader>ca', vim.lsp.buf.code_action, '[c]ode [a]ction')

        -- Diagnostics
        lsp_map('<leader>cd', vim.diagnostic.open_float, '[c]ode [d]iagnostic')

        lsp_map('gd', vim.lsp.buf.definition, '[g]oto [d]efinition')
        lsp_map('gD', vim.lsp.buf.declaration, '[g]oto [D]eclartion')
        lsp_map('gr', require('telescope.builtin').lsp_references, '[g]oto [r]eferences')
        lsp_map('gI', require('telescope.builtin').lsp_implementations, '[g]oto [i]mplementation')

        lsp_map('<leader>lr', function()
          vim.cmd 'LspRestart'
        end, '[l]sp [r]estart')

        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
          lsp_map('<leader>lh', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled {})
          end, '[l]sp toggle inlay [h]ints')
        end
      end,
    })

    -- LSP servers and clients are able to communicate to each other what features they support.
    --  By default, Neovim doesn't support everything that is in the LSP specification.
    --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
    --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

    -- TODO: remove when fixed; https://github.com/neovim/neovim/issues/23291
    -- Context: https://www.reddit.com/r/neovim/comments/135fqp9/why_is_pyright_constantly_analyzing_files_it/
    capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false

    -- Make diagnostics pretty
    vim.diagnostic.config(opts.ui.diagnostic_config)
    -- Hover configuration
    vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, opts.ui.float)
    -- Signature help configuration
    vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, opts.ui.float)

    -- Bless folke https://github.com/neovim/neovim/issues/23725#issuecomment-1561364086
    -- local ok, wf = pcall(require, "vim.lsp._watchfiles")
    -- if ok then
    --   wf._watchfunc = function()
    --     return function() end
    --   end
    -- end

    -- Add border to :LspInfo
    require('lspconfig.ui.windows').default_options.border = 'rounded'

    local lspconfig = require('lspconfig')
    require('lspconfig.configs').griptape_ls = {
      default_config = {
        cmd = {"poetry", "run", "--directory", "/Users/collindutter/Documents/griptape/griptape-ls/", "server"},
        filetypes = {'lua', 'python'},
        single_file_support = true,
        root_dir = lspconfig.util.root_pattern('.git'),
        settings = {},
      };
      capabilities = capabilities,
    }
    -- require('lspconfig').griptape_ls.setup {}

    -- Ensure the servers and tools above are installed
    require('mason').setup()

    local ensure_installed = vim.tbl_keys(opts.servers or {})
    require('mason-tool-installer').setup { ensure_installed = ensure_installed, auto_update = true, }

    require('mason-lspconfig').setup {
      handlers = {
        function(server_name)
          local server = opts.servers[server_name] or {}
          -- This handles overriding only values explicitly passed
          -- by the server configuration above. Useful when disabling
          -- certain features of an LSP (for example, turning off formatting for tsserver)
          server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
          require('lspconfig')[server_name].setup(server)
        end,
      },
    }
  end,
}
