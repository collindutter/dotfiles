-- Plugins that provide formatting capabilities
return {
  {
    -- Formatter
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        python = { 'black' },
        lua = { 'stylua' },
      },
    },
    keys = {
      {
        '<leader>cf',
        function()
          require('conform').format { async = true, lsp_fallback = false }
        end,
        desc = 'Code format',
      },
    },
  },
}
