-- Uitls

local M = {}

---@param repo string
---@return string
function M.gh(repo) return 'https://github.com/' .. repo end

function M.file_parts(path)
  local dir, name = path:match('^(.*)/([^/]+)$')
  if not name then return path, '' end
  return name, dir == '' and '/' or dir
end

-- Retain the end of a directory path, measuring in display cells, not bytes.
function M.clip_directory(dir, width)
  if width < 1 then return '' end
  if vim.fn.strdisplaywidth(dir) <= width then return dir end
  local length = vim.fn.strchars(dir, true)
  local first, last = 0, length
  while first < last do
    local mid = math.floor((first + last) / 2)
    if vim.fn.strdisplaywidth('…' .. vim.fn.strcharpart(dir, mid, length - mid, true)) <= width then
      last = mid
    else
      first = mid + 1
    end
  end
  return '…' .. vim.fn.strcharpart(dir, first, length - first, true)
end

return M
