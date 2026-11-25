local api = vim.api
local ns = api.nvim_create_namespace 'FylerGitSigns'
local refreshes = {}
local git_status = require 'config.git_status'

-- One gutter cell per folder: keep the most significant descendant status.
local priority = { U = 8, D = 7, M = 6, T = 5, R = 4, C = 3, A = 2, ['?'] = 1 }

local function show_signs(buf, root, rows, files, rename_sources)
  local row_signs = {}
  local function mark(row, sign)
    if row and (not row_signs[row] or priority[sign] > priority[row_signs[row]]) then row_signs[row] = sign end
  end
  local function mark_parents(path, sign)
    local dir = vim.fs.dirname(path)
    while dir do
      mark(rows.directories[dir], sign)
      if dir == root then break end
      local parent = vim.fs.dirname(dir)
      if parent == dir then break end
      dir = parent
    end
  end

  for path, sign in pairs(files) do
    mark(rows.files[path], sign)
    mark_parents(path, sign)
  end
  for _, path in ipairs(rename_sources) do mark_parents(path, 'R') end
  for row, sign in pairs(row_signs) do
    api.nvim_buf_set_extmark(buf, ns, row, 0, { sign_text = sign, sign_hl_group = git_status.highlights[sign] })
  end
end

require('fyler.extensions').register {
  name = 'gutter_git',
  hooks = {
    finder_refresh_post = function(finder, visible)
      local buf = finder.buf_id
      api.nvim_buf_clear_namespace(buf, ns, 0, -1)
      local refresh = {}
      refreshes[buf] = refresh
      if finder.opts.scheme ~= 'file' or vim.fn.executable 'git' == 0 then return end

      local roots, repo_rows = {}, {}
      for i, item in ipairs(visible) do
        local is_dir = item.type == 'directory'
        local path = is_dir and item.path:gsub('/+$', '') or item.path
        local dir = vim.fs.dirname(path)
        if dir and roots[dir] == nil then roots[dir] = vim.fs.root(dir, '.git') or false end
        local root = dir and roots[dir]
        if root then
          repo_rows[root] = repo_rows[root] or { files = {}, directories = {} }
          local rows = is_dir and repo_rows[root].directories or repo_rows[root].files
          rows[path] = i - 1
        end
      end

      local tick = api.nvim_buf_get_changedtick(buf)
      for root, rows in pairs(repo_rows) do
        git_status.read(root, function(files, rename_sources)
          if refreshes[buf] == refresh and api.nvim_buf_is_loaded(buf) and api.nvim_buf_get_changedtick(buf) == tick then
            show_signs(buf, root, rows, files, rename_sources)
          end
        end)
      end
    end,
    finder_close_post = function(finder) refreshes[finder.buf_id] = nil end,
  },
}
