local api = vim.api
local git_status = require 'config.git_status'
local ns = api.nvim_create_namespace 'TelescopeGitSigns'
local M = {}

function M.attach(prompt)
  local status = require('telescope.state').get_status(prompt)
  if not status or vim.fn.executable 'git' == 0 then return end
  local picker = status.picker
  if picker.prompt_title == 'Current Buffer Fuzzy' then return end

  local roots, repos = {}, {}
  local finder = picker.finder
  local function redraw()
    local buf = picker.results_bufnr
    if not api.nvim_buf_is_loaded(buf) or not picker.manager then return end
    if finder ~= picker.finder then
      finder, repos = picker.finder, {}
    end

    api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    local line_count = api.nvim_buf_line_count(buf)
    local index = 0
    for entry in picker.manager:iter() do
      index = index + 1
      if index > picker.max_results then break end
      local row = picker:get_row(index)
      local path = entry.filename or entry.path
      if row >= 0 and row < line_count and type(path) == 'string' and path ~= '' and path ~= '[No Name]' and not path:find('://', 1, true) then
        if not vim.startswith(path, '/') then path = vim.fs.joinpath(entry.cwd or vim.uv.cwd(), path) end
        path = vim.fs.normalize(path, { expand_env = false })
        local dir = vim.fs.dirname(path)
        if roots[dir] == nil then roots[dir] = vim.fs.root(dir, '.git') or false end
        local root = roots[dir]
        if root then
          local repo = repos[root]
          if not repo then
            repo = {}
            repos[root] = repo
            git_status.read(root, function(files)
              if repos[root] ~= repo or not api.nvim_buf_is_loaded(prompt) then return end
              repo.files = files
              redraw()
            end)
          end
          local sign = repo.files and repo.files[path]
          if sign then
            api.nvim_buf_set_extmark(buf, ns, row, 0, {
              virt_text = { { ' ' .. sign .. ' ', git_status.highlights[sign] } },
              virt_text_pos = 'right_align',
            })
          end
        end
      end
    end
  end

  picker:register_completion_callback(redraw)
end

return M
