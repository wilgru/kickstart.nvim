local M = {}

M.highlights = {
  A = 'MiniStatuslineGitAdded',
  M = 'MiniStatuslineGitChanged',
  D = 'MiniStatuslineGitRemoved',
  R = 'Directory',
  C = 'Directory',
  T = 'MiniStatuslineGitChanged',
  U = 'DiagnosticError',
  ['?'] = 'DiagnosticInfo',
}
local conflicts = { DD = true, AU = true, UD = true, UA = true, DU = true, AA = true, UU = true }

function M.read(root, callback)
  vim.system({ 'git', '-C', root, 'status', '--porcelain=v1', '-z', '--untracked-files=all' }, {}, vim.schedule_wrap(function(result)
    local files, rename_sources = {}, {}
    if result.code == 0 then
      -- Porcelain -z gives the destination first for renames/copies, then the source.
      local records = vim.split(result.stdout, '\0', { plain = true, trimempty = true })
      local i = 1
      while i <= #records do
        local record = records[i]
        local status = record:sub(1, 2)
        local index, worktree = status:sub(1, 1), status:sub(2, 2)
        local sign = conflicts[status] and 'U' or (worktree ~= ' ' and worktree or index)
        if M.highlights[sign] then files[vim.fs.joinpath(root, record:sub(4))] = sign end
        if status:find('R', 1, true) and records[i + 1] then
          rename_sources[#rename_sources + 1] = vim.fs.joinpath(root, records[i + 1])
        end
        i = i + (status:find('[RC]') and 2 or 1)
      end
    end
    callback(files, rename_sources)
  end))
end

return M
