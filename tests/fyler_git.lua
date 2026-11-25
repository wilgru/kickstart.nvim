-- Run: sh tests/run.sh tests/fyler_git.lua
local api = vim.api
local root = vim.fn.tempname()
vim.fn.mkdir(root, 'p')
root = vim.uv.fs_realpath(root)

local function git(...)
  local args = { 'git', '-C', root, ... }
  local result = vim.system(args):wait()
  assert(result.code == 0, result.stderr)
end

local function write(name, text) vim.fn.writefile({ text }, vim.fs.joinpath(root, name)) end

local ok, err = xpcall(function()
  git('init', '-q')
  write('clean.txt', 'initial')
  write('modified file.txt', 'initial')
  write('rename me.txt', 'initial')
  vim.fn.mkdir(vim.fs.joinpath(root, 'folder/deep'), 'p')
  write('folder/deep/tracked.txt', 'initial')
  vim.fn.mkdir(vim.fs.joinpath(root, 'clean folder'))
  write('clean folder/tracked.txt', 'initial')
  git('add', '.')
  git('-c', 'user.name=Test', '-c', 'user.email=test@example.invalid', '-c', 'commit.gpgsign=false', '-c', 'core.hooksPath=/dev/null', 'commit', '-qm', 'Initial')
  write('modified file.txt', 'changed')
  git('mv', 'rename me.txt', 'renamed file.txt')
  write('added.txt', 'staged')
  git('add', 'added.txt')
  write('new.txt', 'untracked')
  write('folder/deep/tracked.txt', 'changed')
  write('folder/deep/nested.txt', 'untracked')
  vim.fn.mkdir(vim.fs.joinpath(root, 'new folder'))
  write('new folder/nested.txt', 'untracked')

  require('fyler').open { root_path = root }
  assert(vim.wait(3000, function() return vim.bo.filetype == 'fyler_finder' end), 'Fyler did not open')
  local buf = api.nvim_get_current_buf()
  local ns = api.nvim_get_namespaces().FylerGitSigns
  local expected = {
    ['modified file.txt'] = 'M',
    ['renamed file.txt'] = 'R',
    ['added.txt'] = 'A',
    ['new.txt'] = '?',
    folder = 'M',
    ['new folder'] = '?',
  }
  local marks
  assert(vim.wait(3000, function()
    marks = api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })
    return #marks >= vim.tbl_count(expected)
  end), 'Fyler did not show Git gutter signs')
  assert(#marks == vim.tbl_count(expected), 'Unexpected sign on a clean file or folder')
  local tree = table.concat(api.nvim_buf_get_lines(buf, 0, -1, false), '\n')
  assert(not tree:find('tracked.txt', 1, true), 'Folder signs were not tested on a collapsed tree')
  assert(vim.wo.signcolumn == 'yes', 'Fyler gutter is not visible')
  for _, mark in ipairs(marks) do
    local line = api.nvim_buf_get_lines(buf, mark[2], mark[2] + 1, false)[1]
    local name = line:match('/%d+ (.*)$')
    assert(expected[name] == vim.trim(mark[4].sign_text), 'Wrong sign for row: ' .. line)
    expected[name] = nil
  end
  vim.fn.maparg('<leader>f', 'n', false, true).callback()

  local builtin = require 'telescope.builtin'
  local git_highlights = require('config.git_status').highlights
  for _, picker_name in ipairs { 'find_files', 'git_status' } do
    builtin[picker_name] { cwd = root }
    assert(vim.wait(3000, function() return vim.bo.filetype == 'TelescopePrompt' end), 'Telescope did not open')
    local prompt = api.nvim_get_current_buf()
    local picker = require('telescope.actions.state').get_current_picker(prompt)
    buf = picker.results_bufnr
    ns = api.nvim_get_namespaces().TelescopeGitSigns
    expected = { ['modified file.txt'] = 'M', ['renamed file.txt'] = 'R', ['added.txt'] = 'A', ['new.txt'] = '?' }
    assert(vim.wait(3000, function()
      marks = api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })
      return #marks >= 7
    end), 'Telescope did not show Git indicators: ' .. picker_name)
    assert(#marks == 7, 'Telescope marked a clean file')
    for _, mark in ipairs(marks) do
      local line = api.nvim_buf_get_lines(buf, mark[2], mark[2] + 1, false)[1]
      local name = line:match('([^/]+%.txt)')
      local details = mark[4]
      local sign = vim.trim(details.virt_text[1][1])
      assert(details.virt_text_pos == 'right_align' and details.virt_text[1][2] == git_highlights[sign])
      assert(details.virt_text[1][1] == ' ' .. sign .. ' ', 'Telescope Git sign is not padded')
      for filename, expected_sign in pairs(expected) do
        if name and vim.endswith(name, filename) then
          assert(sign == expected_sign, 'Wrong Telescope sign: ' .. line)
          expected[filename] = nil
        end
      end
    end
    assert(not next(expected), 'Telescope signs were assigned to the wrong rows')
    picker:set_prompt('added.txt')
    assert(vim.wait(3000, function()
      marks = api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })
      return #marks == 1 and vim.trim(marks[1][4].virt_text[1][1]) == 'A'
    end), 'Telescope did not update signs after filtering: ' .. picker_name)
    require('telescope.actions').close(prompt)
  end
end, debug.traceback)

vim.fn.delete(root, 'rf')
if not ok then error(err) end
print('Fyler and Telescope: Git indicator tests passed')
