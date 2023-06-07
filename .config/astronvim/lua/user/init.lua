return {
  colorscheme = "catppuccin-mocha",
  plugins = {
    {
      "jose-elias-alvarez/null-ls.nvim",
      opts = function(_, config)
        local null_ls = require "null-ls"

        -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
        -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
        config.sources = {
          null_ls.builtins.formatting.prettier.with({
            only_local = 'node_modules/.bin',
          }),
          null_ls.builtins.formatting.eslint.with({
            only_local = 'node_modules/.bin',
          }),
          null_ls.builtins.diagnostics.pylint.with({
            prefer_local = '.venv/bin'
          }),
          null_ls.builtins.formatting.black.with({
            prefer_local = '.venv/bin'
          }),
        }
        return config
      end,
    },
    {
      "williamboman/mason-lspconfig.nvim",
      opts = {
        ensure_installed = { "tsserver", 'jedi_language_server', 'eslint', 'lua_ls' },
      },
    },
    {
      "nvim-treesitter/nvim-treesitter",
      opts = {
        ensure_installed = "all",
      },
    },
    {
      'alexghergh/nvim-tmux-navigation',
      lazy = false,
      config = function()
        require('nvim-tmux-navigation').setup {
          disable_when_zoomed = true,
          keybindings = {
            left = "<C-h>",
            down = "<C-j>",
            up = "<C-k>",
            right = "<C-l>",
            last_active = "<C-\\>",
            next = "<C-Space>",
          }
        }
      end
    },
    {
      "hrsh7th/nvim-cmp",
      opts = function(_, opts)
        local cmp = require "cmp"
        opts.mapping["<C-e>"] = function(fallback)
          cmp.mapping.abort()
          local copilot_keys = vim.fn["copilot#Accept"]()
          if copilot_keys ~= "" then
            vim.api.nvim_feedkeys(copilot_keys, "i", true)
          else
            fallback()
          end
        end

        return opts
      end,
    },
    {
      "jay-babu/mason-nvim-dap.nvim",
      opts = {
        handlers = {
          python = function()
            local dap = require "dap"
            dap.adapters.python = {
              type = "executable",
              command = ".venv/bin/python",
              args = {
                "-m",
                "debugpy.adapter",
              },
            }

            dap.configurations.python = {
              {
                type = "python",
                request = "launch",
                name = "Test File",
                program = "${workspaceFolder}/.venv/bin/pytest",
                args = { "${file}" },
              },
            }
          end,
        },
      },
    },
    { "github/copilot.vim", lazy = false },
    { "AstroNvim/astrocommunity" },
    { import = "astrocommunity.colorscheme.catppuccin" },
  },
  options = {
    g = {
      copilot_no_tab_map = true,
      copilot_assume_mapped = true,
      copilot_tab_fallback = "",
      python3_host_prog = '~/.virtualenvs/py3nvim/bin/python'
    },
    opt = {
      shell = "/bin/bash"
    }
  },
  lsp = {
    formatting = {
      timeout_ms = 15000,
      format_on_save = false
    },
    config = {
      yamlls = {
        settings = {
          yaml = {
            customTags = {
              "!And scalar",
              "!And mapping",
              "!And sequence",
              "!If scalar",
              "!If mapping",
              "!If sequence",
              "!Not scalar",
              "!Not mapping",
              "!Not sequence",
              "!Equals scalar",
              "!Equals mapping",
              "!Equals sequence",
              "!Or scalar",
              "!Or mapping",
              "!Or sequence",
              "!FindInMap scalar",
              "!FindInMap mappping",
              "!FindInMap sequence",
              "!Base64 scalar",
              "!Base64 mapping",
              "!Base64 sequence",
              "!Cidr scalar",
              "!Cidr mapping",
              "!Cidr sequence",
              "!Ref scalar",
              "!Ref mapping",
              "!Ref sequence",
              "!Sub scalar",
              "!Sub mapping",
              "!Sub sequence",
              "!GetAtt scalar",
              "!GetAtt mapping",
              "!GetAtt sequence",
              "!GetAZs scalar",
              "!GetAZs mapping",
              "!GetAZs sequence",
              "!ImportValue scalar",
              "!ImportValue mapping",
              "!ImportValue sequence",
              "!Select scalar",
              "!Select mapping",
              "!Select sequence",
              "!Split scalar",
              "!Split mapping",
              "!Split sequence",
              "!Join scalar",
              "!Join mapping",
              "!Join sequence"
            }
          }
        }
      }
    }
  },
}
