-- Run: sh tests/run.sh tests/native_search_keymaps.lua
local function mapped(key, mode) return next(vim.fn.maparg(key, mode or 'n', false, true)) ~= nil end
for _, key in ipairs { '<leader>sf', '<leader>sm', '<leader>su', '<leader>sg', '<leader>sw', '<leader>sk', '<leader>s.', '<leader>sc' } do
  assert(mapped(key), 'Missing search shortcut: ' .. key)
end
assert(mapped('<leader>sw', 'x'), 'Visual selection search must be available on Space sw')
for _, key in ipairs { '<leader>sh', '<leader>ss', '<leader>sd', '<leader>sr', '<leader>sb', '<leader>sl', '<leader>s/', '<leader>sn' } do
  assert(not mapped(key), 'Removed search shortcut remains: ' .. key)
end
for _, key in ipairs { 's', 'sf', 'sm', 'su', 'sg', 'sw', 'sk', 's.', 'sc', '<leader>a', '<leader>aa', '<leader>af' } do
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
for _, mapping in ipairs(config.mappings) do
  if mapping.lhs == '<leader>f' and mapping.desc == 'Files' then files_icon = mapping.icon end
end
assert(files_icon and files_icon.icon ~= '', 'Files shortcut has no icon')
print('Native search: keymap tests passed')
