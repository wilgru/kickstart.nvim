local picker = require 'config.search'
local M = {}
local api = vim.api

-- Bound subprocess output, cancel on query changes/close, and handle results on
-- the main loop. Commands use argv arrays so queries and paths stay literal.
local function run(argv, cwd, done)
  if vim.fn.executable(argv[1]) ~= 1 then
    vim.schedule(function() done('', 2, 'Missing executable: ' .. argv[1]) end)
    return function() end
  end
  local chunks, bytes, truncated, cancelled, job = {}, 0, false, false, nil
  job = vim.system(argv, {
    cwd = cwd,
    stdout = function(err, data)
      if err or not data or truncated then return end
      bytes = bytes + #data
      if bytes > 8 * 1024 * 1024 then
        truncated = true
        if job then job:kill(15) end
        return
      end
      chunks[#chunks + 1] = data
    end,
  }, function(result)
    vim.schedule(function()
      if not cancelled then done(table.concat(chunks), result.code, result.stderr or '', truncated) end
    end)
  end)
  return function() cancelled = true; if job then pcall(job.kill, job, 15) end end
end

local function entries_from_paths(output, cwd)
  local entries = {}
  for _, path in ipairs(vim.split(output, '\0', { plain = true, trimempty = true })) do
    entries[#entries + 1] = { text = path, path = vim.fs.joinpath(cwd, path) }
  end
  return entries
end

function M.files(opts)
  opts = opts or {}
  local cwd = opts.cwd or vim.fn.getcwd()
  picker.open {
    title = opts.title or 'Files', prompt = opts.prompt,
    load = function(_, done)
      local argv = { 'fd', '--type', 'f', '--type', 'l', '--hidden', '--exclude', '.git', '--exclude', '.jj', '--color', 'never', '--print0' }
      if opts.follow then argv[#argv + 1] = '--follow' end
      return run(argv, cwd, function(output, code, err, truncated)
        done(entries_from_paths(output, cwd), code ~= 0 and err or (truncated and 'File list truncated' or nil))
      end)
    end,
  }
end

function M.changed(unstaged, opts)
  opts = opts or {}
  local cwd = opts.cwd or vim.fn.getcwd()
  picker.open {
    title = unstaged and 'Unstaged files' or 'Modified files', prompt = opts.prompt,
    load = function(_, done)
      local cancelled, cancel = false, nil
      cancel = run({ 'git', 'rev-parse', '--show-toplevel' }, cwd, function(root, code, err)
        if cancelled then return end
        if code ~= 0 then done({}, err); return end
        root = root:gsub('\n$', '')
        local argv = unstaged and { 'git', 'diff', '--name-only', '-z', '--' }
          or { 'git', 'status', '--porcelain=v1', '-z', '--untracked-files=all' }
        cancel = run(argv, root, function(output, status, stderr)
          if status ~= 0 then done({}, stderr); return end
          if unstaged then done(entries_from_paths(output, root)); return end
          local entries, records = {}, vim.split(output, '\0', { plain = true, trimempty = true })
          local i = 1
          while i <= #records do
            local record = records[i]
            local path = record:sub(4)
            entries[#entries + 1] = { text = path, path = vim.fs.joinpath(root, path) }
            -- Porcelain -z puts the rename destination first, then its source.
            if record:sub(1, 2):find('[RC]') then i = i + 1 end
            i = i + 1
          end
          table.sort(entries, function(a, b) return a.text < b.text end)
          done(entries)
        end)
      end)
      return function() cancelled = true; if cancel then cancel() end end
    end,
  }
end

function M.grep(opts)
  opts = opts or {}
  local cwd = opts.cwd or vim.fn.getcwd()
  picker.open {
    title = opts.title or 'Grep', live = true, query = opts.query, prompt = opts.prompt,
    load = function(query, done)
      local argv = { 'rg', '--json', '--smart-case', '--max-count', '100', '--max-columns', '4096' }
      if opts.fixed then argv[#argv + 1] = '--fixed-strings' end
      if query:find('\n', 1, true) then argv[#argv + 1] = '--multiline' end
      vim.list_extend(argv, { '-e', query, '--' })
      vim.list_extend(argv, opts.paths or { '.' })
      return run(argv, cwd, function(output, code, err, truncated)
        local entries = {}
        for line in output:gmatch('[^\n]+') do
          local ok, event = pcall(vim.json.decode, line)
          if ok and event.type == 'match' and event.data.path.text then
            local data = event.data
            local path = data.path.text:gsub('^%./', '')
            local sub = data.submatches[1]
            local col = sub and sub.start + 1 or 1
            entries[#entries + 1] = {
              text = ('%s:%d: %s'):format(path, data.line_number, (data.lines.text or ''):gsub('[\r\n]+$', '')),
              path = path:sub(1, 1) == '/' and path or vim.fs.abspath(vim.fs.joinpath(cwd, path)), lnum = data.line_number,
              col = col, end_col = sub and sub['end'],
            }
            if #entries >= 1000 then truncated = true; break end
          end
        end
        done(entries, code > 1 and not truncated and err or (truncated and 'Results limited; refine your query' or nil))
      end)
    end,
  }
end

function M.word(visual)
  local query = vim.fn.expand '<cword>'
  if visual then
    local mode = vim.fn.mode()
    local region = vim.fn.getregion(vim.fn.getpos 'v', vim.fn.getpos '.', { type = mode })
    query = table.concat(region, '\n')
    api.nvim_feedkeys(api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', false)
  end
  M.grep { title = 'Search word', query = query, fixed = true }
end

function M.open_files()
  local paths, seen = {}, {}
  for _, buf in ipairs(api.nvim_list_bufs()) do
    local path = api.nvim_buf_get_name(buf)
    if vim.bo[buf].buflisted and vim.bo[buf].buftype == '' and vim.fn.filereadable(path) == 1 and not seen[path] then
      paths[#paths + 1], seen[path] = path, true
    end
  end
  if #paths == 0 then vim.notify('No open files to search.'); return end
  M.grep { title = 'Grep open files', paths = paths }
end

function M.buffers()
  local entries = {}
  for _, buf in ipairs(api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted and vim.bo[buf].buftype == '' then
      local name = api.nvim_buf_get_name(buf)
      entries[#entries + 1] = { text = name == '' and '[No Name]' or vim.fn.fnamemodify(name, ':~:.'), path = name ~= '' and name or nil, buf = buf }
    end
  end
  picker.open { title = 'Buffers', items = entries }
end

function M.oldfiles()
  local entries = {}
  for _, path in ipairs(vim.v.oldfiles) do
    if vim.fn.filereadable(path) == 1 then entries[#entries + 1] = { text = vim.fn.fnamemodify(path, ':~:.'), path = path } end
  end
  picker.open { title = 'Recent files', items = entries }
end

function M.lines()
  local buf, entries = api.nvim_get_current_buf(), {}
  for row, line in ipairs(api.nvim_buf_get_lines(buf, 0, -1, false)) do
    entries[#entries + 1] = { text = ('%d: %s'):format(row, line), path = api.nvim_buf_get_name(buf), buf = buf, lnum = row }
  end
  picker.open { title = 'Buffer lines', items = entries }
end

function M.locations(list)
  local entries = {}
  for _, item in ipairs(list.items or {}) do
    local path = item.filename or (item.bufnr and api.nvim_buf_get_name(item.bufnr))
    entries[#entries + 1] = {
      text = ('%s:%d: %s'):format(path and vim.fn.fnamemodify(path, ':~:.') or '', item.lnum or 1, item.text or ''),
      path = path, buf = item.bufnr, lnum = item.lnum or 1, col = item.col or 1,
    }
  end
  picker.open { title = list.title or 'Locations', items = entries }
end

function M.diagnostics()
  local items = vim.diagnostic.toqflist(vim.diagnostic.get())
  M.locations { title = 'Diagnostics', items = items }
end

function M.commands()
  local entries = {}
  for _, name in ipairs(vim.fn.getcompletion('', 'command')) do
    entries[#entries + 1] = {
      text = name, preview = ':' .. name,
      action = function() api.nvim_feedkeys(':' .. name .. ' ', 'n', false) end,
    }
  end
  picker.open { title = 'Commands', items = entries }
end

function M.help()
  local entries = {}
  for _, tag in ipairs(vim.fn.getcompletion('', 'help')) do
    entries[#entries + 1] = { text = tag, action = function() vim.cmd.help(vim.fn.fnameescape(tag)) end }
  end
  picker.open { title = 'Help', items = entries }
end

function M.keymaps()
  local entries = {}
  for _, mode in ipairs { 'n', 'i', 'v', 'x', 'o', 'c', 't' } do
    local maps = vim.list_extend(api.nvim_get_keymap(mode), api.nvim_buf_get_keymap(0, mode))
    for _, map in ipairs(maps) do
      entries[#entries + 1] = { text = ('%s  %s  %s'):format(mode, map.lhs, map.desc or map.rhs or ''), preview = vim.inspect(map) }
    end
  end
  picker.open { title = 'Keymaps', items = entries }
end

function M.builtin()
  local entries = {}
  local previous = picker.last
  for _, name in ipairs { 'files', 'modified', 'unstaged', 'grep', 'word', 'open files', 'config files', 'buffers', 'oldfiles', 'lines', 'diagnostics', 'commands', 'help', 'keymaps', 'resume' } do
    entries[#entries + 1] = { text = name, action = function()
      if name == 'modified' then M.changed(false)
      elseif name == 'unstaged' then M.changed(true)
      elseif name == 'open files' then M.open_files()
      elseif name == 'config files' then M.files { cwd = vim.fn.stdpath 'config', follow = true, title = 'Config files' }
      elseif name == 'resume' then
        if previous then picker.open(vim.tbl_extend('force', previous.opts, { query = previous.query }))
        else vim.notify('No search to resume.') end
      else M[name]() end
    end }
  end
  picker.open { title = 'Search pickers', items = entries }
end

return M
