-- Run: nvim --headless '+lua dofile("tests/native_search_keymaps.lua")' +qa!
local function mapped(key, mode) return next(vim.fn.maparg(key, mode or 'n', false, true)) ~= nil end
for _, key in ipairs { 'sf', 'sm', 'su', 'sg', 'sw', 'sk', 's.', 'sc' } do
  assert(mapped(key), 'Missing search shortcut: ' .. key)
end
assert(mapped('sw', 'x'), 'Visual selection search must be available on sw')
for _, key in ipairs { 'sh', 'ss', 'sd', 'sr', 'sb', 'sl', 's/', 'sn' } do
  assert(not mapped(key), 'Removed search shortcut remains: ' .. key)
end
for _, key in ipairs {
  '<leader>sf', '<leader>sm', '<leader>su', '<leader>sg', '<leader>sw',
  '<leader>sh', '<leader>sk', '<leader>ss', '<leader>sd', '<leader>sr',
  '<leader>s.', '<leader>sc', '<leader><leader>', '<leader>/', '<leader>s/', '<leader>sn',
} do
  assert(not mapped(key), 'Old search shortcut remains: ' .. key)
end
assert(not mapped('<leader>sw', 'x'))
for _, key in ipairs { 'ys', 'ds', 'cs', 'gsf', 'gsF', 'gsh' } do assert(mapped(key), key) end
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'hello' })
vim.api.nvim_feedkeys('ysiw)', 'xt', false)
assert(vim.api.nvim_get_current_line() == '(hello)', 'ysiw) failed')
vim.api.nvim_feedkeys('ds)', 'xt', false)
assert(vim.api.nvim_get_current_line() == 'hello', 'ds) failed')
vim.api.nvim_feedkeys('ysiw)', 'xt', false)
vim.api.nvim_feedkeys('cs)"', 'xt', false)
assert(vim.api.nvim_get_current_line() == '"hello"', 'cs)" failed')
print('Native search: keymap tests passed')
