-- Highlight on yank
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight_yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Remove highlight after moving cursor
vim.api.nvim_create_autocmd('CursorMoved', {
  group = vim.api.nvim_create_augroup('auto_hlsearch', { clear = true }),
  callback = function()
    if vim.v.hlsearch == 1 then
      local ok, search_count = pcall(vim.fn.searchcount)
      if ok and search_count.exact_match == 0 then
        vim.schedule(function()
          vim.cmd.nohlsearch()
        end)
      end
    end
  end,
})

-- Restore cursor position when opening a buffer
-- https://www.lazyvim.org/configuration/general#auto-commands
vim.api.nvim_create_autocmd('BufReadPost', {
  group = vim.api.nvim_create_augroup('last_loc', { clear = true }),
  callback = function(event)
    local exclude = { 'gitcommit' }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].lazyvim_last_loc then
      return
    end
    vim.b[buf].lazyvim_last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- close some filetypes with <q>
-- https://www.lazyvim.org/configuration/general#auto-commands
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('close_with_q', { clear = true }),
  pattern = {
    'checkhealth',
    'grug-far',
    'help',
    'lspinfo',
    'neotest-output',
    'neotest-output-panel',
    'neotest-summary',
    'qf',
    'dap-float',
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.schedule(function()
      vim.keymap.set('n', 'q', function()
        vim.cmd 'close'
        pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
      end, {
        buffer = event.buf,
        silent = true,
        desc = 'Quit buffer',
      })
    end)
  end,
})

-- Set up LSP-specific keymaps
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp_attach', { clear = true }),
  callback = function(event)
    vim.keymap.set({ 'n' }, '<leader>cd', vim.diagnostic.open_float, { buffer = event.buf, desc = '[c]ode [d]iagnostic' })

    vim.keymap.set({ 'n' }, '<leader>lr', function()
      vim.cmd 'LspRestart'
    end, { buffer = event.buf, desc = '[l]sp [r]estart' })
  end,
})

-- LSP-integrated file renaming
-- https://github.com/folke/snacks.nvim/blob/main/docs/rename.md#oilnvim
vim.api.nvim_create_autocmd('User', {
  pattern = 'OilActionsPost',
  callback = function(event)
    if event.data.actions.type == 'move' then
      Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
    end
  end,
})
