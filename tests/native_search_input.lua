-- Run: sh tests/run.sh tests/native_search_input.lua
local picker = require 'config.search'
local api = vim.api
picker.open {
  title = 'Input test', prompt = false,
  items = { { text = 'alpha' }, { text = 'alphabet' }, { text = 'beta' } },
}
local function type_keys(keys)
  vim.defer_fn(function() api.nvim_feedkeys(api.nvim_replace_termcodes(keys, true, false, true), 't', false) end, 100)
end
local live_error
type_keys('alp')
vim.defer_fn(function()
  local ok, err = pcall(function()
    assert(picker.current.typing, 'Input ended before the live check')
    assert(picker.current.query == 'alp', 'Query did not update before Enter')
    assert(#picker.current.filtered == 2, 'Results did not filter before Enter')
  end)
  if not ok then live_error = err end
  api.nvim_feedkeys(api.nvim_replace_termcodes('<CR>', true, false, true), 't', false)
end, 400)
picker.input()
assert(not live_error, live_error)
picker.update('')
type_keys('alpha<C-n><CR>')
picker.input()
vim.wait(200)
assert(picker.current.query == 'alpha', 'Native command-line input lost query')
assert(#picker.current.filtered == 2, 'Native input did not filter')
assert(api.nvim_win_get_cursor(picker.current.list_win)[1] == 2, 'Ctrl-N selection was lost')
type_keys('<C-u>beta<Esc>')
picker.input()
vim.wait(200)
assert(picker.current.query == 'beta', 'Esc discarded query')
assert(#picker.current.filtered == 1)
type_keys('<C-u><CR>')
picker.input()
vim.wait(200)
assert(picker.current.query == '', 'Clearing query did not reset search')
assert(#picker.current.filtered == 3)
picker.close()
print('Native search: input tests passed')
