-- Code operations use <leader>c; native Vim editing and movement stay intact.
local M = {}
M.moves = {
  { 'ga', '<leader>ia', 'Character codes', { 'n' } },
  { 'g8', '<leader>i8', 'UTF-8 bytes', { 'n' } },
}

function M.setup()
  require('which-key').add {
    { '<leader>c', group = 'Code', icon = { icon = '', color = 'orange' }, mode = { 'n', 'x' } },
    { '<leader>i', group = 'Inspect', icon = { icon = '', color = 'purple' } },
    { '<leader>i8', icon = { icon = '', color = 'purple' } },
    { '<leader>is', icon = { icon = '󰅪', color = 'purple' } },
  }
  for _, move in ipairs(M.moves) do
    vim.keymap.set(move[4] or { 'n', 'x', 'o' }, move[2], move[1], { desc = move[3] })
  end
  vim.keymap.set('n', '<leader>cl', vim.lsp.codelens.run, { desc = 'Run code lens' })
  vim.keymap.set({ 'n', 'x' }, '<leader>o', function() require('config.context').open_link() end, { desc = 'Open link externally' })
end

return M
