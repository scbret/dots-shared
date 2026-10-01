return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    local treesitter = require("nvim-treesitter")
    treesitter.setup({})

    local available = {}
    for _, lang in ipairs(treesitter.get_available()) do
      available[lang] = true
    end
    local pending = {}

    local function enable(buf)
      if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
        return
      end
      local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
      if lang and pcall(vim.treesitter.start, buf, lang) then
        vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end
    end

    local function install(languages)
      local missing = {}
      local installed = treesitter.get_installed()
      for _, lang in ipairs(languages) do
        if available[lang] and not pending[lang] and not vim.tbl_contains(installed, lang) then
          pending[lang] = true
          missing[#missing + 1] = lang
        end
      end
      if #missing == 0 then
        return
      end
      treesitter.install(missing):await(vim.schedule_wrap(function(err)
        for _, lang in ipairs(missing) do
          pending[lang] = nil
        end
        if err then
          vim.notify("Tree-sitter installation failed: " .. tostring(err), vim.log.levels.ERROR)
          return
        end
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) then
            enable(buf)
          end
        end
      end))
    end

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true }),
      callback = function(event)
        enable(event.buf)
        local lang = vim.treesitter.language.get_lang(vim.bo[event.buf].filetype)
        if vim.bo[event.buf].buftype == "" and lang and available[lang] then
          install({ lang })
        end
      end,
    })

    install({ "lua", "bash", "json", "yaml", "markdown", "markdown_inline", "html", "xml", "php" })
  end,
}
