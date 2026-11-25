-- Run: sh tests/run.sh tests/context_menu.lua
local api = vim.api
local context = require 'config.context'
local original_clients = vim.lsp.get_clients
local original_lenses = vim.lsp.codelens.get
local original_open = vim.ui.open
local conform = require 'conform'
local original_formatters = conform.list_formatters
local methods, lenses, formatters, opened = {}, {}, {}, {}
vim.lsp.get_clients = function(opts) return methods[opts.method] and { {} } or {} end
vim.lsp.codelens.get = function() return lenses end
conform.list_formatters = function() return formatters end
vim.ui.open = function(target) opened[#opened + 1] = target end
local buf = api.nvim_create_buf(true, false)
api.nvim_set_current_buf(buf)
local diagnostics = api.nvim_create_namespace 'ContextMenuTest'

local function visible(key) return context.visible { lhs = '<leader>' .. key } end
local function line(text, col)
  api.nvim_buf_set_lines(0, 0, -1, false, { text })
  api.nvim_win_set_cursor(0, { 1, col or 0 })
end

local ok, err = xpcall(function()
  line('plain text')
  assert(not visible('l') and not visible('cr') and not visible('cl') and not visible('cf'))
  assert(not visible('d') and not visible('o') and not visible('g'))
  assert(visible('sf') and visible('f') and visible('tc') and visible('ia') and visible('sw'))
  methods['textDocument/codeAction'], methods['textDocument/rename'] = true, true
  methods['textDocument/formatting'] = true
  assert(visible('l') and visible('cr') and visible('cf'))
  vim.bo.readonly = true
  assert(not visible('l') and not visible('cr') and not visible('cf') and not visible('tc'))
  vim.bo.readonly = false
  methods['textDocument/formatting'] = nil
  formatters = { { available = false } }
  assert(not visible('cf'))
  formatters = { { available = true } }
  assert(visible('cf'))
  methods['textDocument/codeLens'] = true
  assert(not visible('cl'))
  lenses = { { lens = { range = { start = { line = 0 } } } } }
  assert(visible('cl'))
  lenses[1].lens.range.start.line = 1
  assert(not visible('cl'))

  vim.b.gitsigns_status_dict = { added = 0, changed = 0, removed = 0 }
  assert(visible('g') and visible('gb') and visible('gd') and not visible('gs') and not visible('gp'))
  vim.b.gitsigns_status_dict = { added = 1 }
  assert(visible('gs') and visible('gp') and visible('tcc') and visible('tb'))
  vim.bo.readonly = true
  assert(not visible('gs') and visible('gp'))
  vim.bo.readonly = false
  vim.bo.buftype = 'nofile'
  assert(not visible('g') and not visible('cf') and not visible('l') and not visible('tc') and not visible('ia') and not visible('sw'))
  assert(visible('sf') and visible('f'))
  vim.bo.buftype = ''
  vim.b.gitsigns_status_dict = nil
  vim.diagnostic.set(diagnostics, buf, { { lnum = 0, col = 0, message = 'test' } })
  assert(visible('d'))
  vim.diagnostic.reset(diagnostics, buf)
  assert(not visible('d'))

  line('word https://example.com/path.', 0)
  assert(not context.link() and not visible('o'))
  context.open_link()
  assert(#opened == 0, 'Manually invoking Open externally opened a non-link')
  api.nvim_win_set_cursor(0, { 1, 7 })
  assert(context.link() == 'https://example.com/path' and visible('o'))
  context.open_link()
  assert(opened[1] == 'https://example.com/path')
  line('URL:https://example.com/a_(b)', 12)
  assert(context.link() == 'https://example.com/a_(b)')
  line('not_a_link:just-text', 4)
  assert(not context.link())
  api.nvim_buf_call(buf, function() vim.cmd 'noautocmd setlocal filetype=markdown' end)
  line('[a label](https://example.com/a_(b))', 3)
  assert(context.link() == 'https://example.com/a_(b)')
  api.nvim_buf_set_name(buf, vim.fn.getcwd() .. '/tests/context-document.md')
  line('[local](../README.md)', 3)
  assert(context.link() == vim.fn.getcwd() .. '/tests/../README.md')
  line('[label](https://example.com "title")', 3)
  assert(context.link() == 'https://example.com')
  line('rendered link', 2)
  api.nvim_buf_set_extmark(buf, diagnostics, 0, 0, { end_col = 8, hl_group = 'Underlined', url = 'https://example.com/rendered' })
  assert(context.link() == 'https://example.com/rendered')
  api.nvim_buf_clear_namespace(buf, diagnostics, 0, -1)

  -- Popup filtering must follow the cursor, without deleting any actual keymap.
  api.nvim_exec_autocmds('LspAttach', { buffer = buf, data = { client_id = -1 } })
  api.nvim_exec_autocmds('VimEnter', {})
  vim.wait(100)
  local function entry(key)
    local mode = require('which-key.buf').get { mode = 'n', update = true }
    return mode.tree:find('<leader>' .. key)
  end
  assert(entry('c').mapping.desc == 'Code actions', 'Code actions group label is incorrect')
  assert(entry('i').mapping.icon.icon == vim.fn.nr2char(0xedfa), 'Inspect does not use nf-fa-glasses')
  assert(not entry('d'), 'Diagnostics appeared without buffer diagnostics')
  vim.diagnostic.set(diagnostics, buf, { { lnum = 0, col = 0, message = 'test' } })
  assert(entry('d').keymap.desc == 'Diagnostics', 'Diagnostics palette label is incorrect')
  assert(vim.fn.maparg('<leader>d', 'n', false, true).callback == vim.diagnostic.setloclist)
  assert(not next(vim.fn.maparg('<leader>q', 'n', false, true)), 'Old diagnostics shortcut remains')
  vim.diagnostic.reset(diagnostics, buf)
  line('word https://example.com', 8)
  assert(entry('o'))
  api.nvim_win_set_cursor(0, { 1, 0 })
  assert(not entry('o'), 'Open externally stayed visible after moving off the link')
  assert(next(vim.fn.maparg('<leader>o', 'n', false, true)), 'Filtering deleted the actual shortcut')
  methods = {}
  formatters = {}
  assert(not entry('l') and not entry('c'), 'Unsupported language tools or empty Code actions group remained visible')
  assert(not entry('g'), 'Git page remained visible outside an attached Git buffer')
  vim.bo.buftype = 'nofile'
  assert(not entry('t') and not entry('i'), 'Editing-only groups remained in a scratch buffer')
  assert(entry('s') and entry('f'), 'Global file/search tools disappeared')
  print('Context-aware leader menu: all tests passed')
end, debug.traceback)

vim.lsp.get_clients = original_clients
vim.lsp.codelens.get = original_lenses
vim.ui.open = original_open
conform.list_formatters = original_formatters
vim.diagnostic.reset(diagnostics, buf)
api.nvim_buf_delete(buf, { force = true })
if not ok then error(err) end
