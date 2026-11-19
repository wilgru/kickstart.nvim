-- Run: nvim --headless '+lua dofile("tests/native_search.lua")' +qa!
local picker = require 'config.search'
local sources = require 'config.search_sources'
local api = vim.api
local root = vim.fn.tempname()
local original_cwd = vim.fn.getcwd()
local original_laststatus, original_showtabline = vim.o.laststatus, vim.o.showtabline
local open = picker.open
picker.open = function(opts) opts.prompt = false; return open(opts) end

local function wait_for(fn, message) assert(vim.wait(5000, fn, 10), message or 'Timed out') end
local function write(path, lines) vim.fn.writefile(lines, root .. '/' .. path) end
local function git(...)
  local argv = { 'git', '-C', root }
  vim.list_extend(argv, { ... })
  local result = vim.system(argv, { text = true }):wait()
  assert(result.code == 0, result.stderr)
end
local function names()
  local result = {}
  for _, item in ipairs(picker.current.filtered) do result[item.text] = true end
  return result
end
local function close()
  picker.close()
  assert(#api.nvim_list_tabpages() == 1, 'Search tab leaked')
  assert(vim.o.laststatus == original_laststatus and vim.o.showtabline == original_showtabline, 'Editor UI options were not restored')
end

local ok, err = xpcall(function()
  vim.fn.mkdir(root, 'p')
  git('init', '-q')
  git('config', 'user.email', 'search-test@example.invalid')
  git('config', 'user.name', 'Search test')
  write('staged.lua', { 'local old = true' })
  write('unstaged.lua', { 'local old = true' })
  write('both.lua', { 'local old = true' })
  write('deleted.lua', { 'old' })
  write('rename.lua', { 'old' })
  write('.gitignore', { 'ignored.txt' })
  git('add', '.')
  git('commit', '-qm', 'Fixture')
  write('staged.lua', { 'local staged = true' })
  write('both.lua', { 'local staged = true' })
  git('add', 'staged.lua', 'both.lua')
  write('both.lua', { 'local unstaged = true' })
  write('unstaged.lua', { 'local needle = "hello"', 'return needle' })
  write('new file: name.lua', { 'local needle = "space"' })
  write('.hidden.lua', { 'hidden' })
  write('ignored.txt', { 'ignored' })
  git('mv', 'rename.lua', 'renamed file.lua')
  vim.fn.delete(root .. '/deleted.lua')
  vim.fn.chdir(root)

  sources.files()
  wait_for(function() return #picker.current.filtered > 0 end)
  local files = names()
  assert(files['./.hidden.lua'] or files['.hidden.lua'], 'Hidden files missing')
  for name in pairs(files) do assert(not name:find('ignored.txt', 1, true), 'gitignore ignored') end
  assert(#api.nvim_tabpage_list_wins(0) == 2, 'Expected two panels')
  assert(vim.o.laststatus == 3 and vim.o.showtabline == 0, 'Expected a single statusline and no tab header')
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do assert(api.nvim_win_get_config(win).relative == '') end
  assert(require('mini.statusline').config.content.active():find(' Search ', 1, true), 'Search mode pill missing')
  picker.update('unstaged.lua')
  assert(#picker.current.filtered == 1)
  wait_for(function() return api.nvim_buf_get_lines(picker.current.preview_buf, 0, 1, false)[1] == 'local needle = "hello"' end)
  picker.accept()
  assert(vim.fn.expand '%:t' == 'unstaged.lua', 'Wrong file opened')
  assert(#api.nvim_list_tabpages() == 1)

  vim.cmd 'vsplit'
  local source_win = api.nvim_get_current_win()
  sources.files()
  close()
  assert(api.nvim_get_current_win() == source_win and #api.nvim_tabpage_list_wins(0) == 2, 'Source split layout was not restored')
  vim.cmd 'close'

  sources.changed(false)
  wait_for(function() return #picker.current.filtered >= 7 end)
  local changed = names()
  for _, path in ipairs { 'staged.lua', 'unstaged.lua', 'both.lua', 'deleted.lua', 'renamed file.lua', 'new file: name.lua', '.hidden.lua' } do
    assert(changed[path], 'Modified file missing: ' .. path)
  end
  assert(not changed['rename.lua'], 'Rename source leaked')
  close()

  sources.changed(true)
  wait_for(function() return #picker.current.filtered == 3 end)
  local unstaged = names()
  assert(unstaged['unstaged.lua'] and unstaged['both.lua'] and unstaged['deleted.lua'])
  assert(not unstaged['staged.lua'] and not unstaged['new file: name.lua'])
  close()

  sources.grep { query = 'needle' }
  wait_for(function() return #picker.current.filtered == 3 end)
  for _, entry in ipairs(picker.current.filtered) do assert(vim.fn.filereadable(entry.path) == 1, entry.path) end
  picker.update('does-not-exist')
  wait_for(function() return picker.current.message == nil and #picker.current.filtered == 0 end)
  picker.update('[')
  wait_for(function() return picker.current.message and picker.current.message:find('regex parse error', 1, true) end)
  close()

  sources.grep { query = 'needle', paths = { root .. '/new file: name.lua' }, fixed = true }
  wait_for(function() return #picker.current.filtered == 1 end)
  assert(picker.current.filtered[1].path == root .. '/new file: name.lua', 'Absolute grep path corrupted')
  close()

  local before = #vim.fn.getbufinfo { buflisted = 1 }
  api.nvim_buf_set_lines(0, 0, 1, false, { 'local unsaved = true' })
  sources.lines()
  assert(#picker.current.filtered == 2)
  wait_for(function() return api.nvim_buf_get_lines(picker.current.preview_buf, 0, 1, false)[1] == 'local unsaved = true' end)
  close()
  assert(#vim.fn.getbufinfo { buflisted = 1 } == before, 'Preview cluttered buffer list')
  assert(vim.bo.modified, 'Unsaved source buffer changed')
  vim.bo.modified = false

  -- Closing with a pending process must not resurrect the picker.
  sources.grep { query = 'needle' }
  close()
  vim.wait(200)
  assert(picker.current == nil)
  sources.files()
  vim.cmd 'tabclose!'
  vim.wait(100)
  assert(picker.current == nil, 'Manual tab close leaked session')

  for _, fn in ipairs { sources.buffers, sources.oldfiles, sources.commands, sources.help, sources.keymaps, sources.builtin, sources.diagnostics } do
    fn()
    assert(picker.current)
    close()
  end
  picker.open { title = 'Previous search', query = 'hello', items = { { text = 'hello' } } }
  close()
  sources.builtin()
  local menu = names()
  assert(menu['open files'] and menu['config files'] and menu.resume, 'Search menu is missing a picker')
  picker.update('resume')
  picker.accept()
  assert(picker.current.opts.title == 'Previous search' and picker.current.query == 'hello', 'Menu resume reopened the menu')
  close()
  assert(package.loaded['fzf-lua'] == nil and package.loaded.telescope == nil)
  print('Native search: all tests passed')
end, debug.traceback)

picker.close()
picker.open = open
vim.fn.chdir(original_cwd)
vim.fn.delete(root, 'rf')
if not ok then error(err) end
