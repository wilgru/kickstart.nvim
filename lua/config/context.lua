-- Lightweight context checks for Which-key. Never request LSP data or run
-- subprocesses while building a popup.
local M = {}
local api = vim.api

local function text_buffer() return vim.bo.buftype == '' end
local function editable() return text_buffer() and vim.bo.modifiable and not vim.bo.readonly end
local function supports(method) return #vim.lsp.get_clients { bufnr = 0, method = method } > 0 end

local function url(value)
  local scheme = value:match('^([%a][%w+.-]*):')
  if not scheme or not vim.tbl_contains({ 'http', 'https', 'ftp', 'ftps', 'file', 'mailto', 'ssh', 'tel' }, scheme:lower()) then return end
  return value
end

local function link_target(target)
  if url(target) then return target end
  -- Relative Markdown links resolve beside the source document, not the cwd.
  if target:match('^[%a][%w+.-]*:') or target:sub(1, 1) == '#' then return end
  local path = target:gsub('#.*$', '')
  if path == '' then return end
  if path:sub(1, 1) == '/' then return path end
  local name = api.nvim_buf_get_name(0)
  return vim.fs.joinpath(name ~= '' and vim.fs.dirname(name) or vim.fn.getcwd(), path)
end

function M.link()
  local cursor = api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]
  -- OSC-8/rendered hyperlinks represented by extmark URL metadata.
  local marks = api.nvim_buf_get_extmarks(0, -1, { row, col }, { row, col }, {
    details = true, type = 'highlight', overlap = true,
  })
  for _, mark in ipairs(marks) do
    if mark[4].url and url(mark[4].url) then return mark[4].url end
  end
  local line, pos = api.nvim_get_current_line(), col + 1
  if vim.bo.filetype == 'markdown' or vim.bo.filetype == 'markdown_inline' then
    local start = 1
    while true do
      local first, opening = line:find('%[[^%]]*%]%(', start)
      if not first then break end
      local depth, last = 1, opening
      while depth > 0 and last < #line do
        last = last + 1
        local char = line:sub(last, last)
        if line:sub(last - 1, last - 1) ~= '\\' then
          if char == '(' then depth = depth + 1 end
          if char == ')' then depth = depth - 1 end
        end
      end
      if depth == 0 and pos >= first and pos <= last then
        local contents = vim.trim(line:sub(opening + 1, last - 1))
        local target = contents:match('^<(.-)>') or contents:match('^(%S+)')
        if target then return link_target(target:gsub('\\([()%[%] ])', '%1')) end
      end
      start = last + 1
    end
  end
  local start = 1
  while true do
    local first, last = line:find("[%a][%w+.-]*:[^%s<>\"']+", start)
    if not first then return end
    local target = line:sub(first, last):gsub('[%.,;!%]%}]+$', '')
    -- A closing parenthesis belongs to the link only if balanced by an opener.
    while target:sub(-1) == ')' do
      local _, opens = target:gsub('%(', '')
      local _, closes = target:gsub('%)', '')
      if closes <= opens then break end
      target = target:sub(1, -2)
    end
    if pos >= first and pos < first + #target and url(target) then return target end
    start = url(target) and last + 1 or first + 1
  end
end

function M.open_link()
  local target = M.link()
  if not target then return end
  local _, err = vim.ui.open(target)
  if err then vim.notify(err, vim.log.levels.ERROR) end
end

function M.visible(mapping)
  local lhs = mapping.lhs:gsub('<[Ll]eader>', function() return vim.g.mapleader or '\\' end):gsub('<[Ss]pace>', ' ')
  local leader = vim.g.mapleader or '\\'
  if lhs:sub(1, #leader) ~= leader then return true end
  local key = lhs:sub(#leader + 1)
  if key == 'o' then return M.link() ~= nil end
  if key == 'l' then return editable() and supports 'textDocument/codeAction' end
  if key == 'cr' then return editable() and supports 'textDocument/rename' end
  if key == 'cl' then
    if not text_buffer() or not supports 'textDocument/codeLens' then return false end
    local row = api.nvim_win_get_cursor(0)[1] - 1
    for _, item in ipairs(vim.lsp.codelens.get { bufnr = 0 }) do
      if item.lens.range.start.line == row then return true end
    end
    return false
  end
  if key == 'cf' then
    if not editable() then return false end
    local conform = package.loaded.conform
    if conform then
      for _, formatter in ipairs(conform.list_formatters(0)) do if formatter.available then return true end end
    end
    return supports 'textDocument/formatting' or supports 'textDocument/rangeFormatting'
  end
  if key:sub(1, 1) == 'g' or key == 'tb' or key == 'tw' then
    local status = vim.b.gitsigns_status_dict
    if not text_buffer() or not status then return false end
    if key:match('^g[sSrRpiq]$') then
      return (status.added or 0) + (status.changed or 0) + (status.removed or 0) > 0
        and (not key:match('^g[sSrR]$') or editable())
    end
    return true
  end
  if key == 'th' then return text_buffer() and supports 'textDocument/inlayHint' end
  if key:match('^tc') or key:match('^t~') then return editable() end
  if key:sub(1, 1) == 'i' and key ~= 'i' then return text_buffer() and api.nvim_get_current_line() ~= '' end
  if key == 'sw' then return text_buffer() and vim.fn.expand '<cword>' ~= '' end
  if key == 'sm' or key == 'su' then return vim.fs.root(vim.fn.getcwd(), '.git') ~= nil end
  if key == 'sr' then return #vim.v.oldfiles > 0 end
  if key == 'd' then return #vim.diagnostic.get(0) > 0 end
  return true
end

return M
