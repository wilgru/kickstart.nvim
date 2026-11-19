-- Invoked by tests/run.sh in an isolated Neovim process for each test.
-- Plugins can leave intentionally caught startup errors in v:errmsg. Only
-- inspect messages produced during the test itself.
vim.v.errmsg = ''
local ok, err = xpcall(function()
  local path = vim.env.NVIM_TEST_FILE
  assert(path and path ~= '', 'NVIM_TEST_FILE must name a test script')
  dofile(path)
  assert(vim.v.errmsg == '', 'Neovim error during test: ' .. vim.v.errmsg)
end, debug.traceback)

if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd 'cquit 1'
else
  vim.cmd 'qa!'
end
