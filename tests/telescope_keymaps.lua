-- Run: sh tests/run.sh tests/telescope_keymaps.lua
local function mapped(key, mode) return next(vim.fn.maparg(key, mode or 'n', false, true)) ~= nil end
local builtin = require 'telescope.builtin'
for suffix, picker in pairs {
  sf = 'find_files', sm = 'git_status', sg = 'live_grep', sw = 'grep_string',
  sk = 'keymaps', sr = 'oldfiles', sc = 'commands', so = 'buffers',
} do
  local key = '<leader>' .. suffix
  assert(vim.fn.maparg(key, 'n', false, true).callback == builtin[picker], 'Missing Telescope shortcut: ' .. key)
end
assert(mapped('<leader>sw', 'x'), 'Visual selection search must be available on Space sw')
assert(vim.fn.maparg('<leader>so', 'n', false, true).desc == 'Open buffers')
assert(vim.fn.maparg('<leader>/', 'n', false, true).desc == 'Forward search')
for _, suffix in ipairs { 'b', 'h', 's', 'd', '.', '/', 'n', 'l', 'u' } do
  assert(not mapped('<leader>s' .. suffix), 'Extra search shortcut remains: ' .. suffix)
end
for _, key in ipairs { '<leader><leader>', 's', 'sf', 'sm', 'su', 'sg', 'sw', 'sk', 's.', 'sc', '<leader>a', '<leader>aa', '<leader>af' } do
  assert(not mapped(key), 'Old search shortcut remains: ' .. key)
end
assert(not mapped('s', 'x') and not mapped('sw', 'x'))
for _, key in ipairs { 'ys', 'ds', 'cs', 'gsf', 'gsF', '<leader>is' } do assert(mapped(key), key) end
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'hello' })
vim.api.nvim_feedkeys('ysiw)', 'xt', false)
assert(vim.api.nvim_get_current_line() == '(hello)', 'ysiw) failed')
vim.api.nvim_feedkeys('ds)', 'xt', false)
assert(vim.api.nvim_get_current_line() == 'hello', 'ds) failed')
vim.api.nvim_feedkeys('ysiw)', 'xt', false)
vim.api.nvim_feedkeys('cs)"', 'xt', false)
assert(vim.api.nvim_get_current_line() == '"hello"', 'cs)" failed')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'hello' })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('sX<Esc>', true, false, true), 'xt', false)
assert(vim.api.nvim_get_current_line() == 'Xello', 'Native s was not restored')
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('ciwchanged<Esc>', true, false, true), 'xt', false)
assert(vim.api.nvim_get_current_line() == 'changed', 'Native c was not preserved')
assert(mapped('<leader>f') and not mapped('\\'), 'Fyler must use Space f, not backslash')
vim.bo.modified = false
vim.fn.maparg('<leader>f', 'n', false, true).callback()
assert(vim.wait(3000, function() return vim.bo.filetype == 'fyler_finder' end), 'Fyler did not open')
local statusline = require 'mini.statusline'
local display = vim.api.nvim_eval_statusline(statusline.config.content.active(), {}).str
local mode = statusline.section_mode { trunc_width = 120 }
assert(display:find(mode, 1, true), 'Fyler does not show the standard Normal mode label')
assert(not display:find('fyler', 1, true), 'Fyler URI leaked into the statusline')
assert(vim.api.nvim_buf_get_name(0):match('^fyler[^:]*://'), 'Fyler internal buffer URI was changed')
local close = vim.fn.maparg('<leader>f', 'n', false, true)
assert(close.buffer == 1 and close.callback, 'Fyler has no Space f close binding')
assert(not mapped('\\'), 'Backslash remains mapped inside Fyler')
close.callback()
assert(vim.wait(1000, function() return vim.bo.filetype ~= 'fyler_finder' end), 'Fyler did not close')
vim.api.nvim_exec_autocmds('VimEnter', {})
vim.wait(100)
assert(not mapped('s') and not mapped('c'), 'A popup hijacked native s/c after startup')
local config = require 'which-key.config'
assert(config.options.icons.group == '', 'Leader groups still have + prefixes')
assert(vim.fn.maparg('<leader>f', 'n', false, true).desc == 'Files', 'Fyler shortcut is not labeled Files')
local files_icon
local icons = {}
for _, mapping in ipairs(config.mappings) do
  if mapping.lhs == '<leader>f' and mapping.desc == 'Files' then files_icon = mapping.icon end
  if mapping.icon then icons[mapping.lhs] = mapping.icon.icon end
end
assert(files_icon and files_icon.icon ~= '', 'Files shortcut has no icon')
assert(icons['<leader>/'] == '', 'Forward search has the wrong icon')
for suffix, icon in pairs { f = '󰈔', m = '', g = '', w = '󰦨', k = '', r = '󰋚', c = '', o = '' } do
  assert(icons['<leader>s' .. suffix] == icon, 'Search shortcut has the wrong icon: ' .. suffix)
end
local origin = vim.api.nvim_get_current_win()
vim.o.laststatus, vim.o.cmdheight, vim.o.ruler, vim.o.showcmd = 3, 1, true, true
for _, key in ipairs { '<leader>sc', '<leader>sf', '<leader>/', '<leader>so' } do
  vim.fn.maparg(key, 'n', false, true).callback()
  assert(vim.wait(3000, function() return vim.bo.filetype == 'TelescopePrompt' end), 'Telescope did not open: ' .. key)
  local prompt = vim.api.nvim_get_current_buf()
  assert(vim.o.laststatus == 0 and vim.o.cmdheight == 0 and not vim.o.ruler and not vim.o.showcmd, 'Editor bottom UI is visible')
  assert(not require('telescope.actions.state').get_current_picker(prompt).previewer, 'Telescope preview is enabled: ' .. key)
  require('telescope.actions').close(prompt)
  assert(vim.api.nvim_get_current_win() == origin, 'Telescope did not restore the original window')
  assert(vim.o.laststatus == 3 and vim.o.cmdheight == 1 and vim.o.ruler and vim.o.showcmd, 'Editor bottom UI was not restored')
end
local file = 'status%file.lua'
local dir = ('long-directory/'):rep(12) .. '最終'
vim.api.nvim_buf_set_name(0, dir .. '/' .. file)
vim.bo.modified = true
local wide = statusline.section_filename { trunc_width = 140 }
assert(wide:find('status%%file.lua %#MiniStatuslineFileinfo#', 1, true), 'Statusline does not put the filename first')
local narrow = statusline.section_filename { trunc_width = 140, trim_width = vim.fn.strdisplaywidth(dir) - 5 }
assert(narrow:find('status%%file.lua %#MiniStatuslineFileinfo#…最終%#MiniStatuslineFilename#', 1, true), 'Statusline clips the wrong part of the path')
local rendered = vim.api.nvim_eval_statusline(narrow, { maxwidth = 100000 }).str
assert(vim.endswith(rendered, '…最終 ●'), 'Statusline does not put exactly one space before the modified dot')

builtin.find_files { find_command = { 'printf', '%s\\n', dir .. '/' .. file } }
assert(vim.wait(3000, function() return vim.bo.filetype == 'TelescopePrompt' end), 'File picker did not open')
local prompt = vim.api.nvim_get_current_buf()
local picker = require('telescope.actions.state').get_current_picker(prompt)
local row
assert(vim.wait(3000, function()
  for _, line in ipairs(vim.api.nvim_buf_get_lines(picker.results_bufnr, 0, -1, false)) do
    if line:find(file, 1, true) then row = line; return true end
  end
end), 'File picker did not render the result')
assert(row:find(file .. ' …', 1, true) and vim.endswith(row, '最終'), 'File picker clips the wrong part of the path: ' .. row)
assert(vim.fn.strdisplaywidth(row) <= vim.api.nvim_win_get_width(picker.results_win), 'Clipped result exceeds the picker width')
local entry = picker.finder.results[1]
local display, highlights = entry.display(entry)
local icon = display:match('^%S+')
assert(wide:find('%#' .. highlights[1][2] .. '#' .. icon .. '%#MiniStatuslineFilename# ', 1, true), 'File icon does not match Telescope')
assert(highlights[2][2] == 'TelescopePathName' and highlights[3][2] == 'TelescopePathDirectory', 'Picker path highlights are missing')
assert(entry.value == dir .. '/' .. file, 'Path formatting changed the underlying filename')
require('telescope.actions').close(prompt)
for _, name in ipairs { 'live_grep', 'grep_string' } do
  local opts = require('telescope.config').pickers[name]
  local entry = require('telescope.make_entry').gen_from_vimgrep(opts) 'telescope.lua:42:7:example'
  local text, highlights = entry:display()
  local found = false
  for _, highlight in ipairs(highlights) do
    if highlight[2] == 'TelescopeResultsLineNr' then
      assert(text:sub(highlight[1][1] + 1, highlight[1][2]) == '42:7', 'Wrong search location highlight')
      assert(text:find('telescope.lua 42:7 example', 1, true), 'Search locations and preview should be separated by spaces')
      found = true
    end
  end
  assert(found, 'Search location highlight is missing: ' .. name)
end
local buffer = vim.api.nvim_create_buf(true, false)
builtin.buffers()
assert(vim.wait(3000, function() return vim.bo.filetype == 'TelescopePrompt' end), 'Buffer picker did not open')
local buffer_prompt = vim.api.nvim_get_current_buf()
local entry = require('telescope.make_entry').gen_from_buffer { bufnr_width = 3 } {
  bufnr = buffer,
  flag = ' ',
  info = vim.fn.getbufinfo(buffer)[1],
}
local text, highlights = entry:display()
local found = false
for _, highlight in ipairs(highlights) do
  if highlight[2] == 'TelescopeResultsLineNr' then
    assert(text:sub(highlight[1][1] + 1, highlight[1][2]) == tostring(entry.lnum), 'Wrong buffer location highlight')
    assert(not text:find(':' .. entry.lnum, 1, true), 'Buffer location should be separated by a space')
    found = true
  end
end
assert(found, 'Open buffer location highlight is missing')
require('telescope.actions').close(buffer_prompt)
vim.api.nvim_buf_delete(buffer, { force = true })
local location = require('telescope.make_entry').gen_from_quickfix {} {
  filename = 'telescope.lua', lnum = 42, col = 7, text = 'example',
}
local location_text, location_highlights = location:display()
assert(location_text:find('telescope.lua 42:7 example', 1, true), 'Quickfix/LSP locations should be separated by spaces')
local location_hl = location_highlights[#location_highlights]
assert(location_hl[2] == 'TelescopeResultsLineNr', 'Quickfix/LSP location highlight is missing')
assert(
  vim.api.nvim_get_hl(0, { name = 'TelescopeResultsLineNr', link = false }).fg
    == vim.api.nvim_get_hl(0, { name = 'TelescopePathDirectory', link = false }).fg,
  'Search locations should match the grey directory colour'
)

print('Telescope and Fyler: keymap tests passed')
