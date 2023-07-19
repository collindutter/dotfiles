return {
  colorscheme = "catppuccin-mocha",
  mappings = {
    n = {
      ["<leader>T"] = { name = "Test" },
      ["<leader>Tn"] = { ':lua require("neotest").run.run()<cr>', desc = "Run the nearest test" },
      ["<leader>Tc"] = { ':lua require("neotest").run.run(vim.fn.expand("%"))<cr>', desc = "Run the current file" },
      ["<leader>Td"] = { ':lua require("neotest").run.run({strategy = "dap"})<cr>', desc = "Debug the nearest test" },
      ["<leader>dt"] = { ':lua require("neotest").run.run({strategy = "dap"})<cr>', desc = "Debug the nearest test" },
      ["<leader>Ts"] = { ':lua require("neotest").run.stop()<cr>', desc = "Stop the nearest test" },
      ["<leader>m"] = { '<cmd>WindowsMaximize<cr>', desc = "Maximize the current window" },
      ["<leader>fp"] = {
        function() require("telescope.builtin").find_files { search_dirs = { "../" } } end,
        desc = "Find parent files",
      }
    },
  },
  options = {
    g = {
      copilot_no_tab_map = true,
      copilot_assume_mapped = true,
      copilot_tab_fallback = "",
      python3_host_prog = '~/.virtualenvs/py3nvim/bin/python',
      editorconfig = false
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
  plugins = {
    {
      "mfussenegger/nvim-dap-python",
      config = function()
        require('dap-python').setup('~/.virtualenvs/debugpy/bin/python')
      end,
      lazy = false
    },
    {
      "jose-elias-alvarez/null-ls.nvim",
      opts = function(_, config)
        local null_ls = require "null-ls"
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
      "github/copilot.vim",
      lazy = false
    },
    {
      "rcarriga/nvim-dap-ui",
      config = function(plugin, opts)
        require "plugins.configs.nvim-dap-ui" (plugin, opts)

        -- disable dap events that are created
        local dap, dapui = require("dap"), require("dapui")
        dap.listeners.before.event_terminated["dapui_config"] = nil
        dap.listeners.before.event_exited["dapui_config"] = nil

        dapui.setup({
          layouts = {
            {
              elements = {
                {
                  id = "scopes",
                  size = 0.75
                },
                {
                  id = "breakpoints",
                  size = 0.25
                },
              },
              position = "left",
              size = 40
            },
            {
              elements = {
                {
                  id = "repl",
                  size = 1
                },
              },
              position = "bottom",
              size = 15
            }
          },
        })
      end,
    },
    {
      "nvim-neotest/neotest",
      ft = { "python" },
      dependencies = {
        "nvim-neotest/neotest-python",
        {
          "folke/neodev.nvim",
          opts = function(_, opts)
            opts.library = opts.library or {}
            if opts.library.plugins ~= true then
              opts.library.plugins = require("astronvim.utils").list_insert_unique(opts.library.plugins, "neotest")
            end
            opts.library.types = true
          end,
        },
      },
      opts = function()
        return {
          adapters = {
            require("neotest-python")({
              dap = { justMyCode = false },
            })
          },
        }
      end,
      config = function(_, opts)
        local neotest_ns = vim.api.nvim_create_namespace "neotest"
        vim.diagnostic.config({
          virtual_text = {
            format = function(diagnostic)
              local message = diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
              return message
            end,
          },
        }, neotest_ns)
        require("neotest").setup(opts)
      end,
    },
    {
      "anuvyklack/windows.nvim",
      dependencies = {
        "anuvyklack/middleclass",
      },
      config = function()
        require('windows').setup({
          autowidth = {
            enable = false,
          },
        })
      end,
      lazy = false
    },
    { "AstroNvim/astrocommunity" },
    { import = "astrocommunity.colorscheme.catppuccin" },
  },
}
