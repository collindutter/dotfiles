return {
  {
    -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
        { path = 'snacks.nvim', words = { 'Snacks' } },
        { path = 'lazy.nvim', words = { 'LazyVim' } },
      },
    },
  },
  {
    'neovim/nvim-lspconfig',
    opts = {
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
      },
    },
    config = function(_, opts)
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
          -- Diagnostics
          vim.keymap.set({ 'n' }, '<leader>cd', vim.diagnostic.open_float, { buffer = event.buf, desc = '[c]ode [d]iagnostic' })

          vim.keymap.set({ 'n' }, '<leader>lr', function()
            vim.cmd 'LspRestart'
          end, { buffer = event.buf, desc = '[l]sp [r]estart' })
        end,
      })

      -- Make diagnostics pretty
      vim.diagnostic.config(opts.diagnostic_config)

      local watch_type = require('vim._watch').FileChangeType

      -- Hack for high CPU https://github.com/neovim/neovim/issues/23291#issuecomment-1712422887
      local function handler(res, callback)
        if not res.files or res.is_fresh_instance then
          return
        end

        for _, file in ipairs(res.files) do
          local path = res.root .. '/' .. file.name
          local change = watch_type.Changed
          if file.new then
            change = watch_type.Created
          end
          if not file.exists then
            change = watch_type.Deleted
          end
          callback(path, change)
        end
      end

      local function watchman(path, _, callback)
        vim.system({ 'watchman', 'watch', path }):wait()

        local buf = {}
        local sub = vim.system({
          'watchman',
          '-j',
          '--server-encoding=json',
          '-p',
        }, {
          stdin = vim.json.encode {
            'subscribe',
            path,
            'nvim:' .. path,
            {
              expression = { 'anyof', { 'type', 'f' }, { 'type', 'd' } },
              fields = { 'name', 'exists', 'new' },
            },
          },
          stdout = function(_, data)
            if not data then
              return
            end
            for line in vim.gsplit(data, '\n', { plain = true, trimempty = true }) do
              table.insert(buf, line)
              if line == '}' then
                local res = vim.json.decode(table.concat(buf))
                handler(res, callback)
                buf = {}
              end
            end
          end,
          text = true,
        })

        return function()
          sub:kill 'sigint'
        end
      end

      if vim.fn.executable 'watchman' == 1 then
        require('vim.lsp._watchfiles')._watchfunc = watchman
      end
    end,
  },
  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = {
      'neovim/nvim-lspconfig',
    },
    opts = {
      --  Available keys are:
      --  - cmd (table): Override the default command used to start the server
      --  - filetypes (table): Override the default list of associated filetypes for the server
      --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
      --  - settings (table): Override the default settings passed when initializing the server.
      --  For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
      servers = {
        jsonls = {},
        pyright = {
          settings = {
            pyright = {
              -- Using Ruff's import organizer
              disableOrganizeImports = true,
            },
            python = {
              pythonPath = '.venv/bin/python',
              analysis = {
                useLibraryCodeForTypes = true,
                typeCheckingMode = 'basic',
                autoSearchPaths = true,
                diagnosticMode = 'openFilesOnly',
              },
            },
          },
        },
        ruff = {
          -- These are provided by pyright
          -- This removes a redundant "No information found" message
          -- https://github.com/astral-sh/ruff-lsp/issues/78#issuecomment-2395880563
          on_attach = function(client, _)
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.hoverProvider = false
          end,
        },
        marksman = {},
        ts_ls = {},
        html = {},
        typos_lsp = {},
        harper_ls = {},
        jinja_lsp = {
          filetypes = { 'jinja', 'jinja2', 'j2', 'htmldjango' },
        },
        yamlls = {
          settings = {
            yaml = {
              customTags = {
                --- CloudFormation
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
                --- Mkdocs
                '!ENV',
              },
            },
          },
        },
        lua_ls = {
          on_init = function(client)
            local path = client.workspace_folders[1].name
            if vim.loop.fs_stat(path .. '/.luarc.json') or vim.loop.fs_stat(path .. '/.luarc.jsonc') then
              return
            end

            client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
              runtime = {
                version = 'LuaJIT',
              },
              -- Make the server aware of Neovim runtime files
              workspace = {
                checkThirdParty = true,
                library = {
                  vim.env.VIMRUNTIME,
                },
              },
            })
          end,
          settings = {
            Lua = {},
          },
        },
        -- angularls = {}, https://github.com/neovim/nvim-lspconfig/issues/3593
      },
    },
    config = function(_, opts)
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      -- Blink enables more LSP capabilities than default Neovim
      local blink_ok, blink = pcall(require, 'blink.cmp')
      if blink_ok then
        capabilities = blink.get_lsp_capabilities(capabilities)
      end
      -- TODO: remove when fixed: https://github.com/neovim/neovim/issues/23291
      -- Context: https://www.reddit.com/r/neovim/comments/135fqp9/why_is_pyright_constantly_analyzing_files_it/
      capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false

      require('mason-lspconfig').setup {
        ensure_installed = {},
        automatic_installation = false,
        handlers = {
          function(server_name)
            local server = opts.servers[server_name]
            if not server then
              return
            end

            -- This handles overriding only values explicitly passed
            -- by the server configuration above. Useful when disabling
            -- certain features of an LSP (for example, turning off formatting for tsserver)
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
          end,
        },
      }
    end,
  },
}
