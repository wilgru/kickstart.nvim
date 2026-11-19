-- Run: sh tests/run.sh tests/navigation_keymaps.lua
local api = vim.api
local function mapping(key, mode) return vim.fn.maparg(key, mode or 'n', false, true) end
-- No native movement or editing command should be disabled.
for _, key in ipairs { 'gg', 'ge', 'gf', 'gt', 'gi', 'g~', 'gu', 'gU', 'gq', 'gw', 'gJ', 'ga', 'g8' } do
  assert(mapping(key).rhs ~= '<Nop>', 'Native command is disabled: ' .. key)
end
for _, key in ipairs { 'g[', 'g]', 'gsf', 'gsF', 'gc', 'gcc' } do assert(next(mapping(key)), key) end
api.nvim_exec_autocmds('LspAttach', { buffer = 0, data = { client_id = -1 } })
for _, key in ipairs { 'gd', 'gD', 'grr', 'gri', 'grt', 'gO', 'gW' } do
  assert(mapping(key).buffer == 1, 'Missing LSP navigation: ' .. key)
end
for _, key in ipairs { '<leader>gv', '<leader>gvg', '<leader>g[', '<leader>g]', '<leader>gsf', '<leader>gsF' } do
  assert(next(mapping(key)) == nil, 'Old navigation remapping remains: ' .. key)
end
assert(mapping('<leader>l').buffer == 1 and mapping('<leader>l', 'x').buffer == 1)
assert(next(mapping('<leader>ca')) == nil)
for _, key in ipairs { 'grn', 'grx', 'gra' } do assert(next(mapping(key)) == nil, key) end
vim.bo.commentstring = '-- %s'
api.nvim_buf_set_lines(0, 0, -1, false, { 'hello world' })
api.nvim_feedkeys('gcc', 'xt', false)
assert(api.nvim_get_current_line() == '-- hello world', 'Native commenting failed')
api.nvim_feedkeys(' tcc', 'xt', false)
assert(api.nvim_get_current_line() == 'hello world', 'Toggle-menu comment shortcut failed')
api.nvim_feedkeys('g~~', 'xt', false)
assert(api.nvim_get_current_line() == 'HELLO WORLD', 'Native case toggle failed')
api.nvim_buf_set_lines(0, 0, -1, false, { 'first', 'second', 'third' })
api.nvim_win_set_cursor(0, { 3, 0 })
api.nvim_feedkeys('gg', 'xt', false)
assert(api.nvim_win_get_cursor(0)[1] == 1, 'Native gg failed')
api.nvim_feedkeys('2gg', 'xt', false)
assert(api.nvim_win_get_cursor(0)[1] == 2, 'Native gg lost count')
api.nvim_exec_autocmds('VimEnter', {})
assert(mapping('g%').rhs ~= '<Nop>', 'Matchit was disabled')
print('Navigation/toggle keymaps: all tests passed')
