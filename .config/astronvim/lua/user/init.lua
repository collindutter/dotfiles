return {
  colorscheme = "catppuccin-mocha",
  plugins = {
    {
      "jose-elias-alvarez/null-ls.nvim",
      opts = function(_, config)
        -- config variable is the default configuration table for the setup function call
        local null_ls = require "null-ls"

        -- Check supported formatters and linters
        -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
        -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
        config.sources = {
          null_ls.builtins.formatting.prettier,
          null_ls.builtins.code_actions.eslint,
          null_ls.builtins.diagnostics.eslint,
          null_ls.builtins.diagnostics.pylint,
          null_ls.builtins.diagnostics.cfn_lint,
        }
        return config -- return final config table
      end,
    },
    { "catppuccin/nvim", name = "catppuccin" },
  },
  lsp = {
    formatting = {
      timeout_ms = 6000,
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
