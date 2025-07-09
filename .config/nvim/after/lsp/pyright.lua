return {
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
      },
    },
  },
}
