require 'core.options'

require 'core.keymaps'

require 'core.autocmds'

require 'core.lazy'

-- topspace.nvim
local M = {}

M.config = {
  padding_lines = 10,
}

-- Configuration

-- Namespace for virtual text
local ns_id = vim.api.nvim_create_namespace 'topspace'

-- Apply top padding to the current buffer
function M.apply_padding()
  local bufnr = vim.api.nvim_get_current_buf()
  local padding_lines = M.config.padding_lines
  local total_lines = vim.api.nvim_buf_line_count(bufnr)
  local win_height = vim.api.nvim_win_get_height(0)

  -- Clear existing virtual text
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  -- Ensure we don't exceed buffer limits or window height
  padding_lines = math.min(padding_lines, win_height - 1, total_lines - 1)
  -- Create virtual lines
  local virt_lines = {}
  for _ = 1, padding_lines do
    table.insert(virt_lines, { { '', 'NonText' } }) -- Use empty lines styled as `NonText`
  end

  -- Set virtual lines at the beginning of the buffer
  vim.api.nvim_buf_set_extmark(bufnr, ns_id, 0, 0, {
    virt_lines = virt_lines,
    virt_lines_above = true,
  })
end

-- Clear the top padding
function M.clear_padding()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
end

-- Setup autocommands
function M.setup_autocmd()
  vim.api.nvim_create_autocmd({ 'BufEnter', 'WinScrolled', 'VimResized' }, {
    group = vim.api.nvim_create_augroup('topspace', { clear = true }),
    callback = function()
      M.apply_padding()
    end,
  })
end

-- Setup function
function M.setup(user_config)
  M.config = vim.tbl_extend('force', M.config, user_config or {})
  M.setup_autocmd()
end

M.setup {}
