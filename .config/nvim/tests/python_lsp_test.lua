-- Run: nvim --headless -u NONE -l ~/.config/nvim/tests/python_lsp_test.lua
local config_dir = vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, 'S').source:sub(2)))
vim.opt.rtp:prepend(config_dir)
vim.opt.rtp:append(config_dir .. '/after')
vim.opt.rtp:append(vim.fn.stdpath 'data' .. '/lazy/nvim-lspconfig')
local python_lsp = require 'core.python_lsp'
local temp = vim.fn.tempname()
vim.fn.mkdir(temp, 'p')
temp = assert(vim.uv.fs_realpath(temp))
local assertions = 0

local function equal(actual, expected, label)
  assert(vim.deep_equal(actual, expected), label .. ': expected ' .. vim.inspect(expected) .. ', got ' .. vim.inspect(actual))
  assertions = assertions + 1
end

local function write(path, lines)
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  vim.fn.writefile(lines or {}, path)
end

local function repo(name)
  local root = temp .. '/' .. name
  vim.fn.mkdir(root .. '/.git', 'p')
  return root
end

local function selected(file, server, root, label)
  local actual_server, actual_root = python_lsp.select(file)
  equal({ actual_server, actual_root }, { server, root }, label)
end

local original_start = vim.lsp.start
local original_rpc_start = vim.lsp.rpc.start
local ok, err = xpcall(function()
  local default = repo 'default'
  write(default .. '/src/main.py')
  selected(default .. '/src/main.py', 'pyright', default, 'repository fallback')
  write(default .. '/src/pyproject.toml', { '[project]', 'dependencies = ["pyrefly>=1.3.2", "ty"]', '# [tool.ty]' })
  selected(default .. '/src/main.py', 'pyright', default .. '/src', 'generic project and dependency strings')

  local standalone = temp .. '/standalone'
  write(standalone .. '/main.py')
  selected(standalone .. '/main.py', 'pyright', standalone, 'standalone fallback')

  local projects = { { root = default .. '/src', server = 'pyright', file = default .. '/src/main.py' } }
  for _, server in ipairs(python_lsp.servers) do
    local root = repo(server)
    write(root .. '/pyproject.toml', { '  [ tool.' .. server .. '.analysis ] # explicit subtable' })
    write(root .. '/src/pkg/main.py')
    selected(root .. '/src/pkg/main.py', server, root, server .. ' tool table')
    write(root .. '/src/pyproject.toml', { '[project]', 'name = "inner"' })
    selected(root .. '/src/pkg/main.py', server, root, server .. ' inherited through generic inner pyproject')
    projects[#projects + 1] = { root = root, server = server, file = root .. '/src/pkg/main.py' }
  end

  for server, filename in pairs { pyrefly = 'pyrefly.toml', ty = 'ty.toml', pyright = 'pyrightconfig.json' } do
    local root = repo(server .. '-file')
    write(root .. '/' .. filename)
    selected(root .. '/pkg/main.py', server, root, filename .. ' dedicated config')
  end

  local outer = repo 'outer'
  write(outer .. '/pyrefly.toml')
  write(outer .. '/nested/ty.toml')
  selected(outer .. '/nested/src/main.py', 'ty', outer .. '/nested', 'nearest explicit checker wins')
  vim.fn.mkdir(outer .. '/isolated/.git', 'p')
  selected(outer .. '/isolated/src/main.py', 'pyright', outer .. '/isolated', 'nested repository isolation')
  write(outer .. '/worktree/.git', { 'gitdir: /unused' })
  selected(outer .. '/worktree/src/main.py', 'pyright', outer .. '/worktree', 'worktree isolation')
  write(temp .. '/pyrefly.toml')
  selected(default .. '/src/main.py', 'pyright', default .. '/src', 'config beyond repository ignored')

  local conflict = repo 'conflict'
  write(conflict .. '/pyproject.toml', { '[tool.pyright]', '[tool.basedpyright]', '[tool.ty]', '[tool.pyrefly]' })
  selected(conflict .. '/main.py', 'pyrefly', conflict, 'deterministic same-directory precedence')

  -- Exercise Neovim's enabled-config FileType path without launching any servers.
  local starts = {}
  vim.lsp.start = function(config, opts)
    starts[opts.bufnr] = starts[opts.bufnr] or {}
    table.insert(starts[opts.bufnr], { config.name, config.root_dir })
  end
  python_lsp.setup()
  for _, project in ipairs(projects) do
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(buf, project.file)
    project.buf = buf
    vim.bo[buf].filetype = 'python'
  end
  vim.wait(1000, function()
    for _, project in ipairs(projects) do
      if not starts[project.buf] then
        return false
      end
    end
    return true
  end)
  for _, project in ipairs(projects) do
    equal(starts[project.buf], { { project.server, project.root } }, project.server .. ' exclusive concurrent buffer activation')
  end
  equal(vim.lsp.config.pyright.settings.pyright.disableOrganizeImports, true, 'Pyright Ruff integration preserved')
  local lsp_spec = dofile(config_dir .. '/lua/plugins/lsp.lua')[2]
  equal(lsp_spec.opts.automatic_enable.exclude, python_lsp.servers, 'Mason excludes all managed checkers')
  local mason_tools = dofile(config_dir .. '/lua/plugins/mason.lua')[2].opts.ensure_installed
  for _, server in ipairs { 'pyright', 'pyrefly', 'ty' } do
    equal(vim.tbl_contains(mason_tools, server), true, server .. ' installation requested')
  end

  -- Stub executable checks so both command paths are independent of server installation.
  local original_executable = vim.fn.executable
  local local_bin = projects[2].root .. '/.venv/bin/pyrefly'
  local mason_bin = vim.fn.stdpath 'data' .. '/mason/bin/pyrefly'
  vim.fn.executable = function(path)
    return (path == local_bin or path == mason_bin) and 1 or 0
  end
  equal(python_lsp.command('pyrefly', projects[2].root), { local_bin, 'lsp' }, 'local venv preferred')
  equal(python_lsp.command('pyrefly', default), { mason_bin, 'lsp' }, 'Mason fallback')
  vim.fn.executable = original_executable
  for _, server in ipairs(python_lsp.servers) do
    local captured
    vim.lsp.rpc.start = function(cmd, dispatchers, opts)
      captured = { cmd = cmd, dispatchers = dispatchers, opts = opts }
      return 'stub-rpc'
    end
    local root = projects[2].root
    local dispatchers = {}
    local client_config = { root_dir = root, cmd_env = { TEST = 'yes' }, detached = false }
    equal(vim.lsp.config[server].cmd(dispatchers, client_config), 'stub-rpc', server .. ' command factory')
    equal(captured.cmd, python_lsp.command(server, root), server .. ' per-client command')
    equal(captured.opts, { cwd = root, env = client_config.cmd_env, detached = false }, server .. ' RPC launch options')
  end

  local margin = vim.env.HOME .. '/Projects/personal/margin'
  if vim.uv.fs_stat(margin .. '/pyproject.toml') then
    selected(margin .. '/src/config/settings.py', 'pyrefly', margin, 'real Margin selection')
  else
    print 'SKIP real Margin selection: checkout unavailable'
  end
end, debug.traceback)
vim.lsp.start = original_start
vim.lsp.rpc.start = original_rpc_start
vim.lsp.enable(python_lsp.servers, false)
vim.fn.delete(temp, 'rf')
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd 'cquit 1'
end
print(('PASS python_lsp_test.lua (%d assertions)'):format(assertions))
vim.cmd 'qa!'
