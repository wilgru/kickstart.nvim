-- Native search: no plugin or terminal-based picker required.
local search = require 'config.search_sources'
local function map(key, action, desc) vim.keymap.set('n', 's' .. key, action, { desc = desc }) end

map('f', search.files, 'Files')
map('m', function() search.changed(false) end, 'Modified files')
map('u', function() search.changed(true) end, 'Unstaged files')
map('g', search.grep, 'Grep')
map('w', search.word, 'Current word')
vim.keymap.set('x', 'sw', function() search.word(true) end, { desc = 'Selected text' })
map('k', search.keymaps, 'Keymaps')
map('.', search.oldfiles, 'Recent files')
map('c', search.commands, 'Commands')

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('native-search-lsp-attach', { clear = true }),
  callback = function(event)
    local function lspmap(key, fn, desc)
      vim.keymap.set('n', key, fn, { buffer = event.buf, desc = desc })
    end
    local opts = { on_list = search.locations }
    lspmap('grr', function() vim.lsp.buf.references(nil, opts) end, '[G]oto [R]eferences')
    lspmap('gri', function() vim.lsp.buf.implementation(opts) end, '[G]oto [I]mplementation')
    lspmap('grd', function() vim.lsp.buf.definition(opts) end, '[G]oto [D]efinition')
    lspmap('grt', function() vim.lsp.buf.type_definition(opts) end, '[G]oto [T]ype Definition')
    lspmap('gO', function() vim.lsp.buf.document_symbol(opts) end, 'Open Document Symbols')
    lspmap('gW', function() vim.lsp.buf.workspace_symbol('', opts) end, 'Open Workspace Symbols')
  end,
})
