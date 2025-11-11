-- ~/.config/nvim/lua/plugins/zk.lua
return {
  {
    "zk-org/zk-nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    ft = { "markdown" },
    cmd = {
      "ZkNew", "ZkNotes", "ZkBacklinks", "ZkTags", "ZkIndex", "ZkInsertLink", "ZkCd",
      "ZkFollowLink", "ZkFindByTag",
      "ZkNewDefault", "ZkNewJournal", "ZkNewJeep", "ZkNewMeeting",
      "ZkDeleteNote", "ZkRetitleNote",
      "ZkFindJeep", "ZkFindMeeting", "ZkFindJournal",
      "CloseBufferPicker",
    },
    keys = {
      { "<leader>n",  group = "Zk" },

      -- Create
      { "<leader>nn", "<cmd>ZkNewDefault<cr>",  desc = "New note in notes/ (default.md)" },
      { "<leader>nd", "<cmd>ZkNewJournal<cr>",  desc = "New daily journal (daily.md)" },
      { "<leader>nj", "<cmd>ZkNewJeep<cr>",     desc = "New Jeep note in jeep/ (jeep.md)" },
      { "<leader>nm", "<cmd>ZkNewMeeting<cr>",  desc = "New Meeting note in meeting/ (meeting.md)" },

      -- Find (all + by tag)
      { "<leader>nf", "<cmd>ZkNotes<cr>",       desc = "Find Note (all)" },
      { "<leader>nt", "<cmd>ZkFindByTag<cr>",   desc = "Find by Tag(s)" },
      { "<leader>fj", "<cmd>ZkFindJournal<cr>", desc = "Find Journal notes (journal/)" },

      -- Linking & backlinks
      { "<leader>nl", "<cmd>ZkInsertLink<cr>",  desc = "Insert Link" },
      { "<leader>nb", "<cmd>ZkBacklinks<cr>",   desc = "Backlinks" },
      { "<leader>ng", "<cmd>ZkFollowLink<cr>",  desc = "Follow [[link]] under cursor" },

      -- File ops
      { "<leader>rm", "<cmd>ZkDeleteNote<cr>",  desc = "Delete a note (picker + confirm)" },
      { "<leader>rn", "<cmd>ZkRetitleNote<cr>", desc = "Retitle a note (picker + title)" },

      -- Buffers
      { "<leader>cb", "<cmd>CloseBufferPicker<cr>", desc = "Close a buffer (picker)" },
    },
    config = function()
      --------------------------------------------------------------------------
      -- zk.nvim base setup (Telescope picker + LSP)
      --------------------------------------------------------------------------
      require("zk").setup({
        picker = "telescope",
        lsp = {
          config = {
            name = "zk",
            cmd = { "zk", "lsp" },
            filetypes = { "markdown" },
          },
          auto_attach = { enabled = true },
        },
      })

      --------------------------------------------------------------------------
      -- Follow [[link]] with <CR> in markdown
      --------------------------------------------------------------------------
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function(args)
          vim.keymap.set("n", "<CR>", vim.lsp.buf.definition, { buffer = args.buf, desc = "Follow [[link]]" })
        end,
      })

      --------------------------------------------------------------------------
      -- Manual "follow link" command (warn if LSP not attached)
      --------------------------------------------------------------------------
      vim.api.nvim_create_user_command("ZkFollowLink", function()
        local clients = (vim.lsp.get_clients and vim.lsp.get_clients({ bufnr = 0 }))
          or vim.lsp.get_active_clients()
        if clients and #clients > 0 then
          vim.lsp.buf.definition()
        else
          vim.notify("zk LSP not attached. Open a note inside your notebook or set $ZK_NOTEBOOK_DIR.", vim.log.levels.WARN)
        end
      end, {})

      --------------------------------------------------------------------------
      -- Tag search: pick tags then open matching notes
      --------------------------------------------------------------------------
      vim.api.nvim_create_user_command("ZkFindByTag", function()
        local zk = require("zk")
        zk.pick_tags({}, nil, function(picked)
          if not picked or #picked == 0 then return end
          local names = vim.tbl_map(function(t) return t.name end, picked)
          zk.edit({ tags = names }) -- Telescope picker
        end)
      end, {})

      --------------------------------------------------------------------------
      -- Telescope helpers
      --------------------------------------------------------------------------
      local pickers    = require("telescope.pickers")
      local finders    = require("telescope.finders")
      local conf       = require("telescope.config").values
      local actions    = require("telescope.actions")
      local action_st  = require("telescope.actions.state")

      local function split_lines(s)
        local t = {}
        if not s or s == "" then return t end
        for line in s:gmatch("([^\n\r]+)") do table.insert(t, line) end
        return t
      end

      local function uniq_sorted(tbl)
        local seen, out = {}, {}
        for _, v in ipairs(tbl or {}) do
          if v and v ~= "" and not seen[v] then
            seen[v] = true
            table.insert(out, v)
          end
        end
        table.sort(out, function(a,b) return a:lower() < b:lower() end)
        return out
      end

      local function find_buf_by_name(filepath)
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(b) and vim.api.nvim_buf_get_name(b) == filepath then
            return b
          end
        end
        return nil
      end

      --------------------------------------------------------------------------
      -- Title fetchers (by subdir) + single generic Telescope prompt
      --------------------------------------------------------------------------
      local function titles_from_dir(dir, callback)
        -- `zk list <dir>` prints titles of notes within that subfolder
        local cmd = { "zk", "list", dir, "--format", "{{title}}", "--quiet" }
        if vim.system then
          vim.system(cmd, { text = true }, function(res)
            local titles = uniq_sorted(split_lines(res.stdout or ""))
            vim.schedule(function() callback(titles) end)
          end)
        else
          local out = vim.fn.systemlist(table.concat(cmd, " "))
          callback(uniq_sorted(out or {}))
        end
      end

      -- One prompt builder that accepts a "fetch titles" function
      local function telescope_title_prompt_with(fetch_titles_fn, prompt, cb)
        fetch_titles_fn(function(existing)
          pickers.new({}, {
            prompt_title = prompt,
            finder = finders.new_table({ results = existing }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(bufnr, map)
              local function accept_current_line()   -- create from typed text
                local line = action_st.get_current_line() or ""
                actions.close(bufnr)
                if line ~= "" then cb(line) else cb(nil) end
              end
              local function accept_selected()       -- use highlighted entry's title
                local entry = action_st.get_selected_entry()
                actions.close(bufnr)
                local val = entry and entry[1] or ""
                if val ~= "" then cb(val) else cb(nil) end
              end
              map("i", "<CR>", accept_current_line)  -- Enter = take typed text
              map("n", "<CR>", accept_current_line)
              map("i", "<C-y>", accept_selected)     -- Ctrl-y = take highlighted
              map("n", "<C-y>", accept_selected)
              return true
            end,
          }):find()
        end)
      end

      --------------------------------------------------------------------------
      -- Get zk's ZkNew command for creators
      --------------------------------------------------------------------------
      local zk_new = require("zk.commands").get("ZkNew")

      --------------------------------------------------------------------------
      -- New note creators (each pulls titles from the right folder)
      --------------------------------------------------------------------------
      vim.api.nvim_create_user_command("ZkNewDefault", function()
        telescope_title_prompt_with(function(cb)
          titles_from_dir("notes", cb)
        end, "New Note Title (notes/)", function(title)
          zk_new({ dir = "notes", template = "default.md", title = title })
        end)
      end, {})

      vim.api.nvim_create_user_command("ZkNewJournal", function()
        zk_new({ dir = "journal", group = "daily", template = "daily.md" })
      end, {})

      vim.api.nvim_create_user_command("ZkNewJeep", function()
        telescope_title_prompt_with(function(cb)
          titles_from_dir("jeep", cb)
        end, "New Jeep Note Title (jeep/)", function(title)
          zk_new({ dir = "jeep", group = "jeep", template = "jeep.md", title = title })
        end)
      end, {})

      vim.api.nvim_create_user_command("ZkNewMeeting", function()
        telescope_title_prompt_with(function(cb)
          titles_from_dir("meeting", cb)
        end, "New Meeting Note Title (meeting/)", function(title)
          zk_new({ dir = "meeting", group = "meeting", template = "meeting.md", title = title })
        end)
      end, {})

      --------------------------------------------------------------------------
      -- Folder-scoped finders (strict: use hrefs → absolute paths)
      --------------------------------------------------------------------------
      vim.api.nvim_create_user_command("ZkFindJeep", function()
        require("zk").edit({
          hrefs = { vim.fn.expand("$ZK_NOTEBOOK_DIR/jeep") },
        })
      end, {})

      vim.api.nvim_create_user_command("ZkFindMeeting", function()
        require("zk").edit({
          hrefs = { vim.fn.expand("$ZK_NOTEBOOK_DIR/meeting") },
        })
      end, {})

      vim.api.nvim_create_user_command("ZkFindJournal", function()
        require("zk").edit({
          hrefs = { vim.fn.expand("$ZK_NOTEBOOK_DIR/journal") },
        })
      end, {})
      --------------------------------------------------------------------------
      -- Delete note picker (entire notebook)
      --------------------------------------------------------------------------
      vim.api.nvim_create_user_command("ZkDeleteNote", function()
        local cmd = { "zk", "list", "--format", "{{absPath}}", "--quiet" }
        local function start_picker(paths)
          if not paths or #paths == 0 then
            vim.notify("No notes found to delete.", vim.log.levels.INFO)
            return
          end
          local entries = {}
          for _, p in ipairs(paths) do
            table.insert(entries, {
              value = p,
              display = vim.fn.fnamemodify(p, ":~:."),
              ordinal = p,
            })
          end
          pickers.new({}, {
            prompt_title = "Delete a note (Enter to select)",
            finder = finders.new_table({
              results = entries,
              entry_maker = function(e) return e end,
            }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(bufnr, map)
              local function do_delete()
                local entry = action_st.get_selected_entry()
                if not entry or not entry.value then return end
                local path = entry.value
                actions.close(bufnr)
                vim.ui.select({ "No", "Yes" }, { prompt = ("Delete file?\n%s"):format(path) }, function(choice)
                  if choice ~= "Yes" then return end
                  local b = find_buf_by_name(path)
                  if b then pcall(vim.api.nvim_buf_delete, b, { force = true }) end
                  local ok, err = pcall(vim.fn.delete, path)
                  if ok and err == 0 then
                    vim.notify("Deleted: " .. path, vim.log.levels.INFO)
                  else
                    vim.notify("Failed to delete: " .. path, vim.log.levels.ERROR)
                  end
                end)
              end
              map("i", "<CR>", do_delete)
              map("n", "<CR>", do_delete)
              return true
            end,
          }):find()
        end
        if vim.system then
          vim.system(cmd, { text = true }, function(res)
            local paths = split_lines(res.stdout or "")
            vim.schedule(function() start_picker(paths) end)
          end)
        else
          local out = vim.fn.systemlist(table.concat(cmd, " "))
          start_picker(out)
        end
      end, {})

      --------------------------------------------------------------------------
      -- Retitle note picker (entire notebook) – updates YAML title or first H1
      --------------------------------------------------------------------------
      vim.api.nvim_create_user_command("ZkRetitleNote", function()
        local cmd = { "zk", "list", "--format", "{{absPath}}\t{{title}}", "--quiet" }
        local function start_picker(lines)
          if not lines or #lines == 0 then
            vim.notify("No notes found to retitle.", vim.log.levels.INFO)
            return
          end
          local entries = {}
          for _, line in ipairs(lines) do
            local path, title = line:match("^(.-)\t(.*)$")
            path = path or line
            title = title or ""
            table.insert(entries, {
              value = { path = path, title = title },
              display = (title ~= "" and (title .. "  —  " .. vim.fn.fnamemodify(path, ":~:.")) or vim.fn.fnamemodify(path, ":~:.")),
              ordinal = (title ~= "" and (title .. " " .. path) or path),
            })
          end
          pickers.new({}, {
            prompt_title = "Retitle a note (pick one)",
            finder = finders.new_table({
              results = entries,
              entry_maker = function(e) return e end,
            }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(bufnr, map)
              local function do_retitle()
                local entry = action_st.get_selected_entry()
                if not entry or not entry.value then return end
                local path = entry.value.path
                local current_title = entry.value.title or ""
                actions.close(bufnr)
                vim.ui.input({ prompt = "New title: ", default = current_title }, function(new_title)
                  if not new_title or new_title == "" then return end

                  -- Load content
                  local lines = vim.fn.readfile(path)
                  if not lines or #lines == 0 then lines = {} end

                  -- detect YAML frontmatter
                  local has_yaml = (#lines >= 3 and lines[1]:match("^%-%-%-"))
                  if has_yaml then
                    local end_yaml
                    for i = 2, #lines do
                      if lines[i]:match("^%-%-%-") then
                        end_yaml = i
                        break
                      end
                    end
                    if end_yaml then
                      local found_title = false
                      for i = 2, end_yaml - 1 do
                        if lines[i]:match("^title:%s*") then
                          lines[i] = "title: " .. new_title
                          found_title = true
                          break
                        end
                      end
                      if not found_title then
                        table.insert(lines, 2, "title: " .. new_title)
                      end
                    end
                  else
                    -- no YAML: change first H1 or insert one
                    local replaced = false
                    for i = 1, #lines do
                      if lines[i]:match("^#%s+") then
                        lines[i] = "# " .. new_title
                        replaced = true
                        break
                      end
                    end
                    if not replaced then
                      table.insert(lines, 1, "# " .. new_title)
                    end
                  end

                  -- write back
                  local ok_write = (vim.fn.writefile(lines, path) == 0)
                  if ok_write then
                    local b = find_buf_by_name(path)
                    if b then vim.api.nvim_buf_call(b, function() vim.cmd("edit") end) end
                    vim.notify("Retitled: " .. new_title, vim.log.levels.INFO)
                  else
                    vim.notify("Failed to write file", vim.log.levels.ERROR)
                  end
                end)
              end
              map("i", "<CR>", do_retitle)
              map("n", "<CR>", do_retitle)
              return true
            end,
          }):find()
        end
        if vim.system then
          vim.system(cmd, { text = true }, function(res)
            local lines = split_lines(res.stdout or "")
            vim.schedule(function() start_picker(lines) end)
          end)
        else
          local out = vim.fn.systemlist(table.concat(cmd, " "))
          start_picker(out)
        end
      end, {})

      --------------------------------------------------------------------------
      -- Buffer closer picker: <leader>cb or :CloseBufferPicker
      --------------------------------------------------------------------------
      vim.api.nvim_create_user_command("CloseBufferPicker", function()
        local bufs = {}
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(b) and vim.fn.buflisted(b) == 1 then
            local name = vim.api.nvim_buf_get_name(b)
            local display = name ~= "" and vim.fn.fnamemodify(name, ":~:.") or ("[No Name] (buf " .. b .. ")")
            table.insert(bufs, {
              bufnr = b,
              value = b,
              display = display,
              ordinal = display .. " " .. tostring(b),
            })
          end
        end
        if #bufs == 0 then
          vim.notify("No listed buffers to close.", vim.log.levels.INFO)
          return
        end

        pickers.new({}, {
          prompt_title = "Close a buffer (Enter to close)",
          finder = finders.new_table({
            results = bufs,
            entry_maker = function(e) return e end,
          }),
          sorter = conf.generic_sorter({}),
          attach_mappings = function(bufnr, map)
            local function do_close()
              local entry = action_st.get_selected_entry()
              if not entry or not entry.bufnr then return end
              local target = entry.bufnr
              actions.close(bufnr)
              local ok, err = pcall(vim.api.nvim_buf_delete, target, { force = false })
              if not ok then
                -- likely E89: buffer has changes or is displayed…
                vim.ui.select({ "No", "Yes" }, { prompt = ("Force delete buffer %d?"):format(target) }, function(choice)
                  if choice == "Yes" then
                    local ok2, err2 = pcall(vim.api.nvim_buf_delete, target, { force = true })
                    if ok2 then
                      vim.notify(("Closed buffer %d"):format(target), vim.log.levels.INFO)
                    else
                      vim.notify(("Failed to close buffer %d: %s"):format(target, tostring(err2)), vim.log.levels.ERROR)
                    end
                  end
                end)
              else
                vim.notify(("Closed buffer %d"):format(target), vim.log.levels.INFO)
              end
            end
            map("i", "<CR>", do_close)
            map("n", "<CR>", do_close)
            return true
          end,
        }):find()
      end, {})
    end,
  },
}

