-- Code operations use <leader>c; native Vim editing and movement stay intact.
local M = {}
M.moves = {
  { 'ga', '<leader>ia', 'Character codes', { 'n' } },
  { 'g8', '<leader>i8', 'UTF-8 bytes', { 'n' } },
}

function M.setup()
  require('which-key').add {
    { '<leader>c', group = 'Code', mode = { 'n', 'x' } },
    { '<leader>i', group = 'Inspect' },
  }
  for _, move in ipairs(M.moves) do
    vim.keymap.set(move[4] or { 'n', 'x', 'o' }, move[2], move[1], { desc = move[3] })
  end
  vim.keymap.set('n', '<leader>cl', vim.lsp.codelens.run, { desc = 'Run code lens' })
  for _, mode in ipairs { 'n', 'x' } do
    local mapping = vim.fn.maparg('gx', mode, false, true)
    if mapping.callback or mapping.rhs then
      vim.keymap.set(mode, '<leader>o', mapping.callback or mapping.rhs, {
        expr = mapping.expr == 1, remap = mapping.noremap == 0, desc = 'Open externally',
      })
    end
  end
end

return M
