-- Native two-pane picker. Providers supply entries, never windows or keymaps.
local M = {}
local api = vim.api
local ns = api.nvim_create_namespace 'NativeSearch'
local limit = 1000

local function valid(s) return M.current == s and api.nvim_tabpage_is_valid(s.tab) end

local function write(buf, lines)
  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

local function scratch()
  local buf = api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'hide'
  vim.bo[buf].swapfile = false
  vim.bo[buf].undolevels = -1
  return buf
end

local function style(win, list)
  api.nvim_win_call(win, function() vim.opt_local.fillchars:append { eob = ' ' } end)
  api.nvim_set_hl(0, 'NativeSearchCursorLine', { bg = 'NONE' })
  api.nvim_set_hl(0, 'NativeSearchWinBar', { bg = 'NONE' })
  vim.wo[win].winhighlight = 'WinBar:NativeSearchWinBar,WinBarNC:NativeSearchWinBar'
    .. (list and ',CursorLine:NativeSearchCursorLine' or '')
  for key, value in pairs {
    number = false, relativenumber = false, signcolumn = 'no', foldcolumn = '0',
    wrap = false, list = false, spell = false, cursorline = list,
    colorcolumn = '', winbar = '', statuscolumn = '', winfixwidth = list,
  } do
    vim.wo[win][key] = value
  end
end

function M.preview()
  local s = M.current
  if not s or not valid(s) then return end
  s.preview_tick = (s.preview_tick or 0) + 1
  local tick = s.preview_tick
  vim.defer_fn(function()
    if not valid(s) or s.preview_tick ~= tick then return end
    local entry = s.filtered[api.nvim_win_get_cursor(s.list_win)[1]]
    api.nvim_buf_clear_namespace(s.preview_buf, ns, 0, -1)
    pcall(vim.treesitter.stop, s.preview_buf)
    vim.bo[s.preview_buf].syntax = ''
    vim.bo[s.preview_buf].filetype = ''
    local lines, message = {}, 'No preview'
    local filename = entry and entry.path
    if entry and entry.preview then
      lines = vim.split(entry.preview, '\n', { plain = true })
    elseif filename or (entry and entry.buf) then
      local loaded = entry.buf or vim.fn.bufnr(filename)
      local stat = filename and vim.uv.fs_stat(filename)
      if loaded >= 0 and api.nvim_buf_is_loaded(loaded) and api.nvim_buf_line_count(loaded) <= 20000 then
        lines = api.nvim_buf_get_lines(loaded, 0, -1, false)
      elseif stat and stat.type == 'file' and stat.size <= 1024 * 1024 then
        local ok, contents = pcall(vim.fn.readfile, filename, 'b', 20000)
        if ok then lines = contents else message = 'Cannot read file' end
      elseif stat and stat.size > 1024 * 1024 then
        message = 'Preview disabled for files larger than 1 MiB'
      else
        message = 'File is unavailable (it may have been deleted)'
      end
      for _, line in ipairs(lines) do
        if line:find('\0', 1, true) then lines, message = {}, 'Binary file'; break end
      end
    end
    write(s.preview_buf, #lines > 0 and lines or { message })
    if entry and #lines > 0 then
      local ft = entry.buf and vim.bo[entry.buf].filetype or (filename and vim.filetype.match { filename = filename, buf = s.preview_buf })
      if ft then
        -- Scratch previews must not run FileType hooks (LSP, formatters, etc.).
        api.nvim_buf_call(s.preview_buf, function() vim.cmd('noautocmd setlocal filetype=' .. ft) end)
        vim.bo[s.preview_buf].syntax = ft
        pcall(vim.treesitter.start, s.preview_buf, ft)
      end
    end
    local row = math.min(entry and entry.lnum or 1, api.nvim_buf_line_count(s.preview_buf))
    api.nvim_win_set_cursor(s.preview_win, { math.max(1, row), 0 })
    api.nvim_win_call(s.preview_win, function() vim.cmd 'normal! zz' end)
    if entry and entry.lnum then
      api.nvim_buf_set_extmark(s.preview_buf, ns, row - 1, 0, { line_hl_group = 'CursorLine' })
      if entry.col then
        local line = api.nvim_buf_get_lines(s.preview_buf, row - 1, row, false)[1] or ''
        local col = math.min(entry.col - 1, #line)
        local finish = math.min(entry.end_col or col + 1, #line)
        if finish > col then
          api.nvim_buf_set_extmark(s.preview_buf, ns, row - 1, col, { end_col = finish, hl_group = 'Search' })
        end
      end
    end
    -- input() owns the command line, so buffer changes need an explicit redraw.
    if s.typing then vim.cmd 'redraw' end
  end, 40)
end

local function render(s, entries, message)
  if not valid(s) then return end
  s.filtered = entries
  s.message = message
  local lines = {}
  for _, entry in ipairs(entries) do lines[#lines + 1] = entry.text:gsub('[\r\n\t]', ' ') end
  write(s.list_buf, #lines > 0 and lines or vim.split(message or 'No matches', '\n', { plain = true, trimempty = true }))
  api.nvim_win_set_cursor(s.list_win, { 1, 0 })
  M.preview()
  vim.cmd 'redrawstatus'
  if s.typing then vim.cmd 'redraw' end
end

local function filter(s)
  local entries = s.items
  if s.query ~= '' then
    entries = vim.fn.matchfuzzy(entries, s.query, { key = 'text', limit = limit })
  else
    entries = vim.list_slice(entries, 1, limit)
  end
  render(s, entries, s.message)
end

function M.update(query)
  local s = M.current
  if not s then return end
  s.query = query
  s.tick = s.tick + 1
  if not s.opts.live then filter(s); return end
  if s.cancel then s.cancel(); s.cancel = nil end
  local tick = s.tick
  if query == '' then render(s, {}, 'Type to search'); return end
  render(s, {}, 'Searching…')
  vim.defer_fn(function()
    if not valid(s) or tick ~= s.tick then return end
    s.cancel = s.opts.load(query, function(entries, message)
      if not valid(s) or tick ~= s.tick then return end
      render(s, entries, message)
    end)
  end, 100)
end

function M.input()
  local s = M.current
  if not s or s.typing then return end
  api.nvim_set_current_win(s.list_win)
  s.typing = true
  local changed = api.nvim_create_autocmd('CmdlineChanged', {
    group = s.group,
    callback = function()
      if vim.fn.getcmdtype() ~= '@' then return end
      local query = vim.fn.getcmdline()
      vim.schedule(function() if valid(s) and query ~= s.query then M.update(query) end end)
    end,
  })
  vim.fn.inputsave()
  local ok, query = pcall(vim.fn.input, { prompt = '', default = s.query })
  vim.fn.inputrestore()
  pcall(api.nvim_del_autocmd, changed)
  s.typing = false
  -- Esc/Ctrl-C return to browsing without discarding the current query.
  if valid(s) and ok and query ~= '' and query ~= s.query then M.update(query) end
  vim.cmd 'redraw'
end

function M.move(delta)
  local s = M.current
  if not s then return end
  local row = api.nvim_win_get_cursor(s.list_win)[1]
  api.nvim_win_set_cursor(s.list_win, { math.max(1, math.min(#s.filtered, row + delta)), 0 })
  M.preview()
end

function M.status()
  local s = M.current
  if not s or api.nvim_get_current_tabpage() ~= s.tab then return end
  local entry = s.filtered[api.nvim_win_get_cursor(s.list_win)[1]]
  return s.opts.title, entry and (entry.path or entry.text) or '', #s.filtered
end

function M.close()
  local s = M.current
  if not s then return end
  M.current = nil
  M.last = { opts = s.opts, query = s.query }
  if s.cancel then s.cancel() end
  pcall(api.nvim_del_augroup_by_id, s.group)
  vim.o.laststatus, vim.o.showtabline = s.laststatus, s.showtabline
  if api.nvim_tabpage_is_valid(s.tab) and #api.nvim_list_tabpages() > 1 then
    api.nvim_set_current_tabpage(s.tab)
    vim.cmd 'tabclose!'
  end
  for _, buf in ipairs { s.list_buf, s.preview_buf } do
    if api.nvim_buf_is_valid(buf) then api.nvim_buf_delete(buf, { force = true }) end
  end
  if api.nvim_win_is_valid(s.source_win) then api.nvim_set_current_win(s.source_win) end
  vim.cmd 'redrawstatus'
end

function M.accept()
  local s = M.current
  if not s then return end
  local entry = s.filtered[api.nvim_win_get_cursor(s.list_win)[1]]
  if not entry then return end
  M.close()
  if entry.action then entry.action(); return end
  if entry.buf and api.nvim_buf_is_valid(entry.buf) then
    api.nvim_set_current_buf(entry.buf)
  elseif entry.path then
    vim.cmd.edit(vim.fn.fnameescape(entry.path))
  end
  if entry.lnum then
    local row = math.min(entry.lnum, api.nvim_buf_line_count(0))
    local line = api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ''
    api.nvim_win_set_cursor(0, { row, math.min((entry.col or 1) - 1, #line) })
    vim.cmd 'normal! zvzz'
  end
end

function M.open(opts)
  if M.current then M.close() end
  local s = {
    opts = opts, query = opts.query or '', items = opts.items or {}, filtered = {}, tick = 0,
    source_win = api.nvim_get_current_win(), laststatus = vim.o.laststatus, showtabline = vim.o.showtabline,
  }
  vim.cmd 'tabnew'
  s.tab = api.nvim_get_current_tabpage()
  s.list_win = api.nvim_get_current_win()
  local initial = api.nvim_get_current_buf()
  s.list_buf, s.preview_buf = scratch(), scratch()
  api.nvim_win_set_buf(s.list_win, s.list_buf)
  if not vim.bo[initial].modified and api.nvim_buf_get_name(initial) == '' then api.nvim_buf_delete(initial, { force = true }) end
  vim.cmd 'rightbelow vsplit'
  s.preview_win = api.nvim_get_current_win()
  api.nvim_win_set_buf(s.preview_win, s.preview_buf)
  style(s.list_win, true)
  style(s.preview_win, false)
  api.nvim_win_set_width(s.list_win, math.max(20, math.floor(vim.o.columns * 0.35)))
  api.nvim_set_current_win(s.list_win)
  vim.bo[s.list_buf].filetype = 'native-search'
  M.current = s
  -- One shared statusline and no tab header: only the two panels and divider.
  vim.o.laststatus, vim.o.showtabline = 3, 0
  s.group = api.nvim_create_augroup('NativeSearchSession', { clear = true })
  api.nvim_create_autocmd('TabEnter', {
    group = s.group,
    callback = function()
      local active = api.nvim_get_current_tabpage() == s.tab
      vim.o.laststatus = active and 3 or s.laststatus
      vim.o.showtabline = active and 0 or s.showtabline
    end,
  })
  api.nvim_create_autocmd('CursorMoved', { group = s.group, buffer = s.list_buf, callback = M.preview })
  api.nvim_create_autocmd('TabClosed', {
    group = s.group,
    callback = function() if not api.nvim_tabpage_is_valid(s.tab) then M.close() end end,
  })
  for _, buf in ipairs { s.list_buf, s.preview_buf } do
    local function map(key, action) vim.keymap.set('n', key, action, { buffer = buf, silent = true, nowait = true }) end
    map('q', M.close)
    map('<Esc>', M.close)
    map('i', M.input)
    map('<CR>', M.accept)
    map('j', function() M.move(1) end)
    map('k', function() M.move(-1) end)
    map('<Tab>', function()
      api.nvim_set_current_win(api.nvim_get_current_win() == s.list_win and s.preview_win or s.list_win)
    end)
    vim.keymap.set('c', '<C-n>', function() vim.schedule(function() M.move(1) end); return '' end, { buffer = buf, expr = true })
    vim.keymap.set('c', '<C-p>', function() vim.schedule(function() M.move(-1) end); return '' end, { buffer = buf, expr = true })
  end
  if opts.load and not opts.live then
    render(s, {}, 'Loading…')
    s.cancel = opts.load('', function(entries, message)
      if not valid(s) then return end
      s.items, s.message = entries, message
      filter(s)
    end)
  else
    M.update(s.query)
  end
  if opts.prompt ~= false then vim.schedule(function() if valid(s) then M.input() end end) end
end

function M.resume()
  if not M.last then vim.notify('No search to resume.'); return end
  M.open(vim.tbl_extend('force', M.last.opts, { query = M.last.query }))
end

return M
