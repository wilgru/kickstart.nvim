-- guess-indent, gitsigns, which-key, colorscheme, todo-comments, mini modules
local util = require 'config.util'
local gh = util.gh

do
  -- [[ Installing and Configuring Plugins ]]
  --
  -- To install a plugin simply call `vim.pack.add` with its git url.
  -- This will download the default branch of the plugin, which will usually be `main` or `master`
  -- You can also have more advanced specs, which we will talk about later.
  --
  -- For most plugins its not enough to install them, you also need to call their `.setup()` to start them.
  --
  -- For example, lets say we want to install `guess-indent.nvim` - a plugin for
  -- automatically detecting and setting the indentation.
  --
  -- We first install it from https://github.com/NMAC427/guess-indent.nvim
  -- and then call its `setup()` function to start it with default settings.
  vim.pack.add { gh 'NMAC427/guess-indent.nvim' }
  require('guess-indent').setup {}

  -- Adds git related signs to the gutter, as well as utilities for managing changes
  -- See `:help gitsigns` to understand what each configuration key does.
  vim.pack.add { gh 'lewis6991/gitsigns.nvim' }
  require('gitsigns').setup {
    signs = {
      add = { text = '+' }, ---@diagnostic disable-line: missing-fields
      change = { text = '~' }, ---@diagnostic disable-line: missing-fields
      delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
      topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
      changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
    },
    on_attach = function(bufnr)
      local gitsigns = require 'gitsigns'

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      map('n', ']c', function()
        if vim.wo.diff then
          vim.cmd.normal { ']c', bang = true }
        else
          gitsigns.nav_hunk 'next'
        end
      end, { desc = 'Jump to next git [c]hange' })

      map('n', '[c', function()
        if vim.wo.diff then
          vim.cmd.normal { '[c', bang = true }
        else
          gitsigns.nav_hunk 'prev'
        end
      end, { desc = 'Jump to previous git [c]hange' })

      -- Actions
      -- visual mode
      map('v', '<leader>gs', function() gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git [s]tage hunk' })
      map('v', '<leader>gr', function() gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git [r]eset hunk' })
      -- normal mode
      map('n', '<leader>gs', gitsigns.stage_hunk, { desc = 'git [s]tage hunk' })
      map('n', '<leader>gr', gitsigns.reset_hunk, { desc = 'git [r]eset hunk' })
      map('n', '<leader>gS', gitsigns.stage_buffer, { desc = 'git [S]tage buffer' })
      map('n', '<leader>gR', gitsigns.reset_buffer, { desc = 'git [R]eset buffer' })
      map('n', '<leader>gp', gitsigns.preview_hunk, { desc = 'git [p]review hunk' })
      map('n', '<leader>gi', gitsigns.preview_hunk_inline, { desc = 'git preview hunk [i]nline' })
      map('n', '<leader>gb', function() gitsigns.blame_line { full = true } end, { desc = 'git [b]lame line' })
      map('n', '<leader>gd', gitsigns.diffthis, { desc = 'git [d]iff against index' })
      map('n', '<leader>gD', function() gitsigns.diffthis '@' end, { desc = 'git [D]iff against last commit' })
      map('n', '<leader>gQ', function() gitsigns.setqflist 'all' end, { desc = 'git hunk [Q]uickfix list (all files in repo)' })
      map('n', '<leader>gq', gitsigns.setqflist, { desc = 'git hunk [q]uickfix list (all changes in this file)' })
      -- Toggles
      map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = 'Toggle Git line blame' })
      map('n', '<leader>tw', gitsigns.toggle_word_diff, { desc = 'Toggle Git word diff' })

      -- Text object
      map({ 'o', 'x' }, 'ih', gitsigns.select_hunk)
    end,
  }

  -- Useful plugin to show you pending keybinds.
  vim.pack.add { gh 'folke/which-key.nvim' }
  require('which-key').setup {
    -- Delay between pressing a key and opening which-key (milliseconds)
    delay = 0,
    filter = function(mapping) return require('config.context').visible(mapping) end,
    icons = { mappings = vim.g.have_nerd_font, group = '' },
    win = { border = 'rounded' },
    -- Document existing key chains
    spec = {
      -- Missing leaf icons inherit their group icon; existing icons take priority.
      { '<leader>', icon = { icon = '󰘳', color = 'grey' }, mode = { 'n', 'x' } },
      { '<leader>f', desc = 'Files', icon = { icon = '󰈔', color = 'blue' } },
      { '<leader>s', group = 'Search', icon = { icon = '', color = 'green' }, mode = { 'n', 'x' } },
      { '<leader>t', group = 'Toggle', icon = { icon = '', color = 'yellow' }, mode = { 'n', 'x' } },
      { '<leader>g', group = 'Git', icon = { icon = '', color = 'orange' }, mode = { 'n', 'x' } },
      { '<leader>l', icon = { icon = '󰌵', color = 'yellow' }, mode = { 'n', 'x' } },
      { '<leader>o', icon = { icon = '󰏌', color = 'blue' }, mode = { 'n', 'x' } },
      { 'g', group = 'g' },
      { 'gr', group = 'LSP navigation' },
    },
  }

  -- [[ Colorscheme ]]
  vim.pack.add { gh 'projekt0n/github-nvim-theme' }
  vim.opt.termguicolors = true
  local palette = require('github-theme.palette').load 'github_dark_high_contrast'
  require('github-theme').setup {
    options = {
      transparent = true,
    },
    specs = {
      all = {
        -- Match ~/.config/zed/themes/github-dark-high-contrast.json.
        syntax = {
          variable = '#d0d4dc',
          ident = '#d0d4dc',
          comment = '#929aa8',
          bracket = '#929aa8',
          param = '#fe9a2d',
          field = '#f0b72f',
          func = '#cb9eff',
          string = '#4ae168',
          type = '#76e3ea',
          number = '#91cbff',
          const = '#fe9a2d',
          keyword = '#ff9492',
          conditional = '#ff9492',
          preproc = '#ff9492',
          operator = '#91cbff',
          builtin0 = '#91cbff',
          builtin1 = '#ff9492',
          builtin2 = '#91cbff',
          regex = '#addcff',
          tag = '#72f088',
        },
      },
    },
    groups = {
      all = {
        Boolean = { fg = '#cb9eff' },
        Label = { fg = '#929aa8' },
        Delimiter = { fg = '#929aa8' },
        Special = { fg = '#d0d4dc' },
        Title = { fg = '#cb9eff', style = 'bold' },
        jsonKeyword = { link = '@property' },
        yamlBlockMappingKey = { link = '@property' },
        yamlFlowMappingKey = { link = '@property' },
        ['@boolean'] = { link = 'Boolean' },
        ['@label'] = { link = 'Label' },
        ['@module'] = { fg = '#ff9492' },
        ['@namespace'] = { link = '@module' },
        ['@constructor'] = { fg = '#ffb757' },
        ['@function.builtin'] = { fg = '#91cbff' },
        ['@function.builtin.lua'] = { link = '@function.builtin' },
        ['@type.builtin'] = { fg = '#ff9492' },
        ['@attribute'] = { fg = '#fe9a2d' },
        ['@tag.attribute'] = { link = '@attribute' },
        ['@tag.attribute.javascript'] = { fg = '#929aa8' },
        ['@tag.attribute.tsx'] = { fg = '#929aa8' },
        ['@tag.javascript'] = { link = '@tag' },
        ['@tag.tsx'] = { link = '@tag' },
        ['@tag.delimiter'] = { fg = '#929aa8' },
        ['@tag.delimiter.javascript'] = { link = '@tag.delimiter' },
        ['@tag.delimiter.tsx'] = { link = '@tag.delimiter' },
        ['@punctuation.delimiter'] = { fg = '#929aa8' },
        ['@punctuation.special'] = { fg = '#929aa8' },
        ['@punctuation.delimiter.markdown'] = { link = '@punctuation.delimiter' },
        ['@punctuation.delimiter.markdown_inline'] = { link = '@punctuation.delimiter' },
        ['@string.special'] = { fg = '#d0d4dc' },
        ['@string.special.url'] = { fg = '#fe9a2d', style = 'italic' },
        ['@markup.strong'] = { fg = '#d0d4dc', style = 'bold' },
        ['@markup.italic'] = { fg = '#d0d4dc', style = 'italic' },
        ['@markup.raw'] = { fg = '#d0d4dc', style = 'italic' },
        ['@markup.link'] = { fg = '#d0d4dc' },
        ['@markup.link.label'] = { fg = '#d0d4dc' },
        ['@markup.link.uri'] = { fg = '#fe9a2d', style = 'italic' },
        ['@markup.list'] = { fg = '#929aa8' },
        ['@markup.heading'] = { link = 'Title' },
        ['@markup.heading.html'] = { link = 'Title' },
        ['@property.json'] = { link = '@property' },
        ['@property.yaml'] = { link = '@property' },
        ['@operator.lua'] = { link = 'Operator' },
        ['@lsp.type.enum'] = { link = '@type' },
        ['@lsp.type.enumMember'] = { link = 'Constant' },
        ['@lsp.type.class'] = { link = '@type' },
        ['@lsp.type.interface'] = { link = '@type' },
        ['@lsp.type.namespace'] = { link = '@module' },
        CopilotSuggestion = { fg = '#929aa8' },
        ['@lsp.type.variable.lua'] = { link = '@variable' },
        ['@property.lua'] = { link = '@variable.member' },
        WhichKeyNormal = { fg = 'fg1', bg = 'NONE' },
        WhichKeyBorder = { fg = 'fg1', bg = 'NONE' },
        WhichKeyTitle = { fg = 'fg1', bg = 'NONE' },
        StatusLine = { fg = 'fg1', bg = 'NONE' },
        StatusLineNC = { fg = palette.gray.base, bg = 'NONE' },
        MsgArea = { fg = palette.gray.base, bg = 'NONE' },
        MiniStatuslineDevinfo = { fg = 'fg1', bg = 'NONE' },
        MiniStatuslineBranch = { fg = palette.green.bright, bg = 'NONE' },
        MiniStatuslineGitAdded = { fg = palette.green.bright, bg = 'NONE' },
        MiniStatuslineGitChanged = { fg = palette.yellow.base, bg = 'NONE' },
        MiniStatuslineGitRemoved = { fg = palette.red.base, bg = 'NONE' },
        MiniStatuslineModified = { fg = palette.blue.base, bg = 'NONE' },
        MiniStatuslineFileinfo = { fg = palette.gray.base, bg = 'NONE' },
        MiniStatuslineFilename = { fg = 'fg1', bg = 'NONE' },
        TelescopePathName = { fg = 'fg1' },
        TelescopePathDirectory = { fg = palette.gray.base },
        TelescopeResultsLineNr = { fg = palette.gray.base },
        MiniStatuslineCommand = { fg = '#000000', bg = palette.gray.base },
        MiniStatuslineCommandCap = { fg = palette.gray.base, bg = 'NONE' },
      },
    },
  }
  vim.cmd.colorscheme 'github_dark_high_contrast'

  vim.api.nvim_create_autocmd({ 'CmdlineEnter', 'CmdlineLeave' }, {
    group = vim.api.nvim_create_augroup('CommandLineColors', { clear = true }),
    callback = function(event)
      local typing = event.event == 'CmdlineEnter' or (vim.v.event.cmdlevel or 0) > 1
      local fg = typing and vim.api.nvim_get_hl(0, { name = 'Normal', link = false }).fg or palette.gray.base
      vim.api.nvim_set_hl(0, 'MsgArea', { fg = fg, bg = 'NONE' })
    end,
  })

  local message_timer = assert(vim.uv.new_timer())
  vim.on_key(function()
    message_timer:start(4000, 0, vim.schedule_wrap(function()
      local mode = vim.api.nvim_get_mode()
      if vim.fn.getcmdtype() ~= '' or mode.blocking then return end
      vim.api.nvim_echo({}, false, {})
    end))
  end, vim.api.nvim_create_namespace 'ClearIdleMessages')
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = 'CommandLineColors',
    callback = function()
      vim.on_key(nil, vim.api.nvim_create_namespace 'ClearIdleMessages')
      message_timer:stop()
      message_timer:close()
    end,
  })

  -- Highlight todo, notes, etc in comments
  vim.pack.add { gh 'folke/todo-comments.nvim' }
  require('todo-comments').setup { signs = false }

  -- [[ mini.nvim ]]
  --  A collection of various small independent plugins/modules
  vim.pack.add { gh 'nvim-mini/mini.nvim' }

  -- If a nerd font is available, load the icons module for pretty icons in various plugins.
  if vim.g.have_nerd_font then
    require('mini.icons').setup()
    -- Used for backwards compatibility with plugins that require `nvim-web-devicons` (e.g. telescope.nvim)
    MiniIcons.mock_nvim_web_devicons()
  end

  -- Better Around/Inside textobjects
  --
  -- Examples:
  --  - va)  - [V]isually select [A]round [)]paren
  --  - yiiq - [Y]ank [I]nside [I]+1 [Q]uote
  --  - ci'  - [C]hange [I]nside [']quote
  require('mini.ai').setup {
    -- NOTE: Avoid conflicts with the built-in incremental selection mappings on Neovim>=0.12 (see `:help treesitter-incremental-selection`)
    mappings = {
      around_next = 'aa',
      inside_next = 'ii',
    },
    n_lines = 500,
  }

  -- Add/delete/replace surroundings (brackets, quotes, etc.)
  --
  -- - ysiw) - surround inner word with parentheses
  -- - ds'   - delete surrounding quotes
  -- - cs)'  - change surrounding parentheses to quotes
  -- Keep bare s available for search; cl is Vim's equivalent substitute action.
  require('mini.surround').setup {
    mappings = {
      add = 'ys',
      delete = 'ds',
      replace = 'cs',
      find = 'gsf',
      find_left = 'gsF',
      highlight = '<leader>is',
    },
  }

  -- Simple and easy statusline.
  --  You could remove this setup call if you don't like it,
  --  and try some other statusline plugin
  local statusline = require 'mini.statusline'
  vim.o.showcmd = true
  vim.o.showcmdloc = 'statusline'
  -- Set `use_icons` to true if you have a Nerd Font
  statusline.setup {
    use_icons = vim.g.have_nerd_font,
    content = {
      active = function()
        local mode, mode_hl = statusline.section_mode { trunc_width = 120 }
        local mode_block = { hl = mode_hl, strings = { mode } }
        if vim.g.have_nerd_font then
          local colors = vim.api.nvim_get_hl(0, { name = mode_hl, link = false })
          vim.api.nvim_set_hl(0, 'MiniStatuslineModeCap', { fg = colors.bg, bg = 'NONE' })
          mode_block = '%#MiniStatuslineModeCap#%#' .. mode_hl .. '# ' .. mode .. ' %#MiniStatuslineModeCap#'
        end
        local command = vim.api.nvim_eval_statusline('%S', {}).str
        local command_block = ''
        if command ~= '' then
          local prompt = vim.g.have_nerd_font and '' or '>'
          command_block = '%#MiniStatuslineFileinfo# ' .. prompt .. ' ' .. command:gsub('%%', '%%%%') .. ' '
        end
        local groups = {
          mode_block,
          {
            hl = 'MiniStatuslineDevinfo',
            strings = {
              statusline.section_git { trunc_width = 40 },
              statusline.section_diff { trunc_width = 75 },
            },
          },
          '%<',
          { hl = 'MiniStatuslineFilename', strings = { statusline.section_filename { trunc_width = 140 } } },
          command_block,
          '', -- Measure without alignment padding before deciding whether to clip.
          {
            hl = 'MiniStatuslineFileinfo',
            strings = {
              statusline.section_lsp { trunc_width = 75 },
              statusline.section_diagnostics { trunc_width = 75 },
              statusline.section_fileinfo { trunc_width = 120 },
              statusline.section_location { trunc_width = 75 },
              statusline.section_searchcount { trunc_width = 75 },
            },
          },
        }
        local function display_width(text)
          return vim.api.nvim_eval_statusline(text, { maxwidth = 100000 }).width
        end
        local width = vim.o.laststatus == 3 and vim.o.columns or vim.api.nvim_win_get_width(0)
        local overflow = display_width(statusline.combine_groups(groups)) - width
        if overflow > 0 then
          groups[4].strings[1] = statusline.section_filename { trunc_width = 140, trim_width = overflow }
          local remaining = display_width(statusline.combine_groups(groups)) - width
          if remaining > 0 then groups[2].strings[1] = statusline.section_git { trunc_width = 40, trim_width = remaining } end
        end
        groups[6] = '%='
        return statusline.combine_groups(groups)
      end,
    },
  }

  -- Clip display text before escaping statusline syntax; preserve UTF-8 characters.
  local function clip(text, max_width, from_start)
    max_width = math.max(1, max_width)
    if vim.fn.strdisplaywidth(text) <= max_width then return text end
    while vim.fn.strdisplaywidth(text) > max_width - 1 do
      local length = vim.fn.strchars(text)
      text = vim.fn.strcharpart(text, from_start and 1 or 0, length - 1)
    end
    return from_start and ('…' .. text) or (text .. '…')
  end

  local section_git = statusline.section_git
  ---@diagnostic disable-next-line: duplicate-set-field
  statusline.section_git = function(args)
    local branch = section_git(args)
    if branch == '' then return '' end
    branch = clip(branch, vim.fn.strdisplaywidth(branch) - (args.trim_width or 0), false)
    return '%#MiniStatuslineBranch#' .. branch:gsub('%%', '%%%%') .. '%#MiniStatuslineDevinfo#'
  end

  local section_filename = statusline.section_filename
  ---@diagnostic disable-next-line: duplicate-set-field
  statusline.section_filename = function(args)
    if vim.bo.filetype == 'fyler_finder' then
      -- Keep Fyler's internal URI intact; only simplify its displayed name.
      local path = vim.api.nvim_buf_get_name(0):gsub('^fyler[^:]*://', '')
      return clip(path, vim.fn.strdisplaywidth(path) - (args.trim_width or 0), true):gsub('%%', '%%%%')
    end
    local modified = vim.bo.modified and ' %#MiniStatuslineModified#●%#MiniStatuslineFilename#' or ''
    local filename = section_filename(args):gsub('%%m', function() return modified end)
    return (filename:gsub('%%[fFt]', function(item)
      local path = vim.api.nvim_eval_statusline(item, { maxwidth = 100000 }).str
      if vim.bo.buftype ~= '' then return (path:gsub('%%', '%%%%')) end
      local name, dir = util.file_parts(path)
      local icon = ''
      if vim.g.have_nerd_font then
        local bufname = vim.api.nvim_buf_get_name(0)
        local glyph, hl
        if bufname ~= '' then
          glyph, hl = MiniIcons.get('file', vim.fs.basename(bufname))
        elseif vim.bo.filetype ~= '' then
          glyph, hl = MiniIcons.get('filetype', vim.bo.filetype)
        end
        if glyph then icon = '%#' .. hl .. '#' .. glyph .. '%#MiniStatuslineFilename# ' end
      end
      local trim = args.trim_width or 0
      if trim > 0 then dir = util.clip_directory(dir, vim.fn.strdisplaywidth(dir) - trim) end
      local suffix = dir == '' and '' or ' %#MiniStatuslineFileinfo#' .. dir:gsub('%%', '%%%%') .. '%#MiniStatuslineFilename#'
      return icon .. name:gsub('%%', '%%%%') .. suffix
    end))
  end

  ---@diagnostic disable-next-line: duplicate-set-field
  statusline.section_diff = function(args)
    if statusline.is_truncated(args.trunc_width) then return '' end
    local diff = vim.b.gitsigns_status_dict
    if not diff then return '' end

    local counts = {}
    for _, change in ipairs {
      { 'added', '+', 'MiniStatuslineGitAdded' },
      { 'changed', '~', 'MiniStatuslineGitChanged' },
      { 'removed', '-', 'MiniStatuslineGitRemoved' },
    } do
      local count = diff[change[1]] or 0
      if count > 0 then counts[#counts + 1] = '%#' .. change[3] .. '#' .. change[2] .. count .. '%#MiniStatuslineDevinfo#' end
    end
    return table.concat(counts, ' ')
  end

  local section_fileinfo = statusline.section_fileinfo
  ---@diagnostic disable-next-line: duplicate-set-field
  statusline.section_fileinfo = function(args)
    local info = section_fileinfo(args)
    if statusline.is_truncated(args.trunc_width) or vim.bo.buftype ~= '' then return '' end
    -- Keep only encoding, format, and size; the filetype icon precedes the filename.
    info = info:match('(%S*%[[^%]]+%] %S+)$') or ''
    if not vim.g.have_nerd_font then return info end
    -- Decorate the default encoding[format] size suffix.
    return (info:gsub('(%S*)%[([^%]]+)%] (%S+)$', function(encoding, format, size)
      if encoding == '' then encoding = vim.o.encoding end
      local details = {}
      if encoding ~= 'utf-8' then details[#details + 1] = ' ' .. encoding end
      if format ~= 'unix' then details[#details + 1] = '󰌑 ' .. format end
      details[#details + 1] = ' ' .. size:gsub('([KMGTPE])iB$', '%1B')
      return table.concat(details, '  ')
    end))
  end

  ---@diagnostic disable-next-line: duplicate-set-field
  statusline.section_lsp = function(args)
    if statusline.is_truncated(args.trunc_width) then return '' end
    local count = #vim.lsp.get_clients { bufnr = 0 }
    if count == 0 then return '' end
    local icon = vim.g.have_nerd_font and '󰰎 ' or ''
    return icon .. count .. (count == 1 and ' LSP' or ' LSPs')
  end

  local section_searchcount = statusline.section_searchcount
  ---@diagnostic disable-next-line: duplicate-set-field
  statusline.section_searchcount = function(args)
    local count = section_searchcount(args)
    if count == '' then return '' end
    return '%#MiniStatuslineFileinfo#' .. (vim.g.have_nerd_font and ' ' or '') .. count
  end

  ---@diagnostic disable-next-line: duplicate-set-field
  statusline.section_location = function()
    return '%#MiniStatuslineFileinfo#' .. (vim.g.have_nerd_font and ' ' or '') .. '%l:%v'
  end

  -- ... and there is more!
  --  Check out: https://github.com/nvim-mini/mini.nvim

  -- [[ Fyler ]]
  -- Browse and edit the file system as a tree in the current window
  vim.pack.add { gh 'FylerOrg/fyler.nvim' }
  local fyler = require 'fyler'
  require 'config.fyler_git'
  fyler.setup {
    kind = 'replace',
    win_opts = {
      number = true,
      relativenumber = true,
    },
    integrations = { icon = vim.g.have_nerd_font and 'mini_icons' or nil },
    extensions = { gutter_git = { enabled = true } },
    mappings = {
      n = {
        ['<leader>f'] = { action = 'close', desc = 'Files' },
      },
    },
  }

  vim.keymap.set('n', '<leader>f', function() fyler.toggle() end, { desc = 'Files' })

  -- [[ Indent guides ]]
  -- Add indentation guides even on blank lines
  -- Enable `lukas-reineke/indent-blankline.nvim`
  -- See `:help ibl`
  -- vim.pack.add { gh 'lukas-reineke/indent-blankline.nvim' }
  -- require('ibl').setup {}
end
