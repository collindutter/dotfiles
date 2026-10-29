return {
  -- These are provided by the project's selected Python type checker
  -- This removes a redundant "No information found" message
  -- https://github.com/astral-sh/ruff-lsp/issues/78#issuecomment-2395880563
  on_attach = function(client, _)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.hoverProvider = false
  end,
}
