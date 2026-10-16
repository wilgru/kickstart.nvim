-- OpenSCAD: syntax highlighting, cheatsheet, snippets, offline manual, fuzzy help
local gh = require('config.util').gh

vim.pack.add { gh 'salkin-mada/openscad.nvim' }

vim.g.openscad_load_snippets = true   -- Load LuaSnip snippets (LuaSnip already installed)
vim.g.openscad_default_mappings = true -- Enable default keymaps
vim.g.openscad_pdf_cmd = 'open'       -- macOS: use `open` to view the offline PDF manual
vim.g.openscad_fuzzy_finder = 'auto'  -- Use fzf-lua if available, otherwise fallback

require('openscad')
