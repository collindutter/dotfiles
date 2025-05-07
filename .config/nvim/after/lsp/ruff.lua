return {
  ruff = {
    -- These are provided by pyright
    -- This removes a redundant "No information found" message
    -- https://github.com/astral-sh/ruff-lsp/issues/78#issuecomment-2395880563
    on_attach = function(client, _)
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.hoverProvider = false
    end,
  },
}
