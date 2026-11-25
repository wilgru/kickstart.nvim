-- Run: sh tests/run.sh tests/action_keymaps.lua
local api = vim.api
local function mapping(key, mode) return vim.fn.maparg(key, mode or 'n', false, true) end
for _, move in ipairs(require('config.actions').moves) do
  assert(mapping(move[1]).rhs ~= '<Nop>', 'Native editing binding disabled: ' .. move[1])
  assert(mapping(move[2]).rhs == move[1], 'Missing code action: ' .. move[2])
end
assert(next(mapping('gx')), 'Native open externally was removed')
for _, key in ipairs { '<leader>cl', '<leader>o', '<leader>cf', '<leader>is', '<leader>isl', '<leader>isn' } do
  assert(next(mapping(key)), 'Missing leader action: ' .. key)
end
for _, key in ipairs { '<leader>aa', '<leader>ar', '<leader>al', '<leader>af', '<leader>au', '<leader>ad' } do
  assert(next(mapping(key)) == nil, 'Old action mapping remains: ' .. key)
end
api.nvim_exec_autocmds('LspAttach', { buffer = 0, data = { client_id = -1 } })
for _, mode in ipairs { 'n', 'x' } do
  local suggestions = mapping('<leader>l', mode)
  assert(suggestions.buffer == 1 and suggestions.desc == 'Language suggestions')
end
for _, key in ipairs { '<leader>ca', '<leader>cd', '<leader>cu', '<leader>cdd', '<leader>cuu', '<leader>cq', '<leader>cw', '<leader>cj' } do
  assert(next(mapping(key)) == nil, 'Redundant code mapping remains: ' .. key)
end
assert(mapping('<leader>cr').buffer == 1)
api.nvim_buf_set_lines(0, 0, -1, false, { 'hello WORLD', 'second LINE' })
api.nvim_feedkeys('gUw', 'xt', false)
assert(api.nvim_get_current_line() == 'HELLO WORLD', 'Uppercase motion failed')
api.nvim_feedkeys('guu', 'xt', false)
assert(api.nvim_get_current_line() == 'hello world', 'Lowercase line failed')
api.nvim_feedkeys('VgU', 'xt', false)
assert(api.nvim_get_current_line() == 'HELLO WORLD', 'Visual uppercase failed')
api.nvim_feedkeys('gJ', 'xt', false)
assert(api.nvim_get_current_line() == 'HELLO WORLDsecond LINE', 'Join without spaces failed')
-- Check the configured Git buffer bindings without staging/resetting any files.
require('gitsigns.config').config.on_attach(api.nvim_get_current_buf())
for _, suffix in ipairs { 's', 'r', 'S', 'R', 'p', 'i', 'b', 'd', 'D', 'q', 'Q' } do
  local key = '<leader>g' .. suffix
  assert(mapping(key).buffer == 1 and (mapping(key).desc or ''):find('git'), 'Missing Git binding: ' .. key)
  assert(next(mapping('<leader>h' .. suffix)) == nil, 'Old Git binding remains')
end
assert(mapping('<leader>gs', 'x').buffer == 1 and mapping('<leader>gr', 'x').buffer == 1)
api.nvim_exec_autocmds('VimEnter', {})
vim.wait(100)
local view = require 'which-key.view'
local checked = 0
for _, mode in ipairs { 'n', 'x' } do
  local tree = require('which-key.buf').get({ mode = mode, update = true }).tree
  tree:walk(function(node)
    if node.path[1] == '<Space>' and (node.keymap or (node.mapping and node.mapping.group)) then
      assert(view.icon(node), 'Leader entry has no icon: ' .. node.keys)
      checked = checked + 1
    end
  end)
  local toggle = tree:find('<leader>t')
  assert(toggle.mapping.desc == 'Toggle', 'Toggle group still has a mnemonic prefix')
end
assert(checked > 20, 'Leader icon check did not inspect the submenu entries')
print('Action/Git keymaps: all tests passed')
