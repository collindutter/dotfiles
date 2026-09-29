return { -- Highlight, edit, and navigate code
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  build = ':TSUpdate',
  branch = 'main',
  config = function()
    local treesitter = require 'nvim-treesitter'
    local available_parsers
    local pending_installs = {}

    local function buffer_lang(buf)
      if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
        return nil
      end

      local ft = vim.bo[buf].filetype
      if ft == '' then
        return nil
      end

      return vim.treesitter.language.get_lang(ft)
    end

    local function has_parser(lang)
      if not lang or lang == '' then
        return false
      end

      local ok, added = pcall(vim.treesitter.language.add, lang)
      return ok and added == true
    end

    local function enable_for_buffer(buf, lang)
      if buffer_lang(buf) ~= lang or not has_parser(lang) then
        return
      end

      local ok, err = pcall(vim.treesitter.start, buf, lang)
      if not ok then
        vim.notify(tostring(err), vim.log.levels.ERROR)
        return
      end

      vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
          vim.wo[win][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
          vim.wo[win][0].foldmethod = 'expr'
        end
      end
    end

    local function parser_is_available(lang)
      available_parsers = available_parsers or treesitter.get_available()
      return vim.tbl_contains(available_parsers, lang)
    end

    local function install_then_enable(buf, lang)
      if not parser_is_available(lang) then
        return
      end

      pending_installs[lang] = pending_installs[lang] or {}
      pending_installs[lang][buf] = true
      if pending_installs[lang].started then
        return
      end
      pending_installs[lang].started = true

      local ok, task = pcall(treesitter.install, lang)
      if not ok then
        pending_installs[lang] = nil
        vim.notify(tostring(task), vim.log.levels.ERROR)
        return
      end

      task:await(function(err, success)
        vim.schedule(function()
          local pending = pending_installs[lang]
          pending_installs[lang] = nil
          if err then
            vim.notify(tostring(err), vim.log.levels.ERROR)
            return
          end
          if success == false or not pending then
            return
          end

          for pending_buf in pairs(pending) do
            if type(pending_buf) == 'number' then
              enable_for_buffer(pending_buf, lang)
            end
          end
        end)
      end)
    end

    vim.api.nvim_create_autocmd('FileType', {
      pattern = { '*' },
      callback = function(args)
        local lang = buffer_lang(args.buf)
        if not lang then
          return
        end

        if has_parser(lang) then
          enable_for_buffer(args.buf, lang)
        else
          install_then_enable(args.buf, lang)
        end
      end,
    })
  end,
}
