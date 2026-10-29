local M = {}

-- Also defines deterministic precedence when a directory configures multiple checkers.
M.servers = { 'pyrefly', 'ty', 'basedpyright', 'pyright' }
local config_files = { pyrefly = 'pyrefly.toml', ty = 'ty.toml', pyright = 'pyrightconfig.json' }
local commands = {
  pyrefly = { 'pyrefly', 'lsp' },
  ty = { 'ty', 'server' },
  basedpyright = { 'basedpyright-langserver', '--stdio' },
  pyright = { 'pyright-langserver', '--stdio' },
}
local project_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', 'Pipfile' }

local function tool_tables(dir)
  local ok, lines = pcall(vim.fn.readfile, dir .. '/pyproject.toml')
  local tools = {}
  if ok then
    for _, line in ipairs(lines) do
      local header, suffix = line:match '^%s*%[([^%]]+)%]%s*(.*)$'
      if header and (suffix == '' or suffix:sub(1, 1) == '#') then
        header = header:gsub('%s+', '')
        for _, server in ipairs(M.servers) do
          local table_name = 'tool.' .. server
          if header == table_name or header:sub(1, #table_name + 1) == table_name .. '.' then
            tools[server] = true
          end
        end
      end
    end
  end
  return tools
end

-- Generic inner pyprojects are fallback roots, not barriers to explicit outer config.
-- A nested repository is a barrier, including worktrees whose .git is a file.
function M.select(path)
  local start = path == '' and vim.fn.getcwd() or vim.fs.dirname(vim.fs.abspath(path))
  local boundary = vim.fs.root(start, '.git')
  local fallback
  local dir = start
  while dir do
    local tools = tool_tables(dir)
    for _, server in ipairs(M.servers) do
      local file = config_files[server]
      if tools[server] or (file and vim.uv.fs_stat(dir .. '/' .. file)) then
        return server, dir
      end
    end
    if not fallback then
      for _, marker in ipairs(project_markers) do
        if vim.uv.fs_stat(dir .. '/' .. marker) then
          fallback = dir
          break
        end
      end
    end
    if dir == boundary then
      break
    end
    local parent = vim.fs.dirname(dir)
    dir = parent ~= dir and parent or nil
  end
  return 'pyright', fallback or boundary or start
end

function M.command(server, root)
  local cmd = vim.deepcopy(commands[server])
  local local_executable = root .. '/.venv/bin/' .. cmd[1]
  local mason_executable = vim.fn.stdpath 'data' .. '/mason/bin/' .. cmd[1]
  if vim.fn.executable(local_executable) == 1 then
    cmd[1] = local_executable
  elseif vim.fn.executable(mason_executable) == 1 then
    cmd[1] = mason_executable
  end
  return cmd
end

function M.setup()
  for _, server in ipairs(M.servers) do
    vim.lsp.config(server, {
      root_dir = function(bufnr, on_dir)
        local selected, root = M.select(vim.api.nvim_buf_get_name(bufnr))
        if selected == server then
          on_dir(root)
        end
      end,
      cmd = function(dispatchers, config)
        return vim.lsp.rpc.start(M.command(server, config.root_dir), dispatchers, {
          cwd = config.cmd_cwd or config.root_dir,
          env = config.cmd_env,
          detached = config.detached,
        })
      end,
    })
  end
  vim.lsp.enable(M.servers)
end

return M
