local gh = require('config.util').gh

do
  -- [[ Fuzzy Finder (files, lsp, etc) ]]
  --
  -- Telescope is a fuzzy finder that comes with a lot of different things that
  -- it can fuzzy find! It's more than just a "file finder", it can search
  -- many different aspects of Neovim, your workspace, LSP, and more!
  --
  -- There are lots of other alternative pickers (like snacks.picker, or fzf-lua)
  -- so feel free to experiment and see what you like!
  --
  -- The easiest way to use Telescope, is to start by doing something like:
  --  :Telescope help_tags
  --
  -- After running this command, a window will open up and you're able to
  -- type in the prompt window. You'll see a list of `help_tags` options and
  -- a corresponding preview of the help.
  --
  -- Two important keymaps to use while in Telescope are:
  --  - Insert mode: <c-/>
  --  - Normal mode: ?
  --
  -- This opens a window that shows you all of the keymaps for the current
  -- Telescope picker. This is really useful to discover what Telescope can
  -- do as well as how to actually do it!

  ---@type (string|vim.pack.Spec)[]
  local telescope_plugins = {
    gh 'nvim-lua/plenary.nvim',
    gh 'nvim-telescope/telescope.nvim',
    gh 'nvim-telescope/telescope-ui-select.nvim',
  }
  if vim.fn.executable 'make' == 1 then table.insert(telescope_plugins, gh 'nvim-telescope/telescope-fzf-native.nvim') end

  -- NOTE: You can install multiple plugins at once
  vim.pack.add(telescope_plugins)

  -- See `:help telescope` and `:help telescope.setup()`
  require('telescope').setup {
    defaults = { preview = false },
    extensions = {
      ['ui-select'] = { require('telescope.themes').get_dropdown() },
    },
  }

  -- Enable Telescope extensions if they are installed
  pcall(require('telescope').load_extension, 'fzf')
  pcall(require('telescope').load_extension, 'ui-select')

  local chrome = vim.api.nvim_create_augroup('telescope-editor-chrome', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    group = chrome,
    pattern = 'TelescopePrompt',
    callback = function(event)
      -- The picker has its own prompt; hide the editor's bottom UI until it closes.
      local saved = { laststatus = vim.o.laststatus, cmdheight = vim.o.cmdheight, ruler = vim.o.ruler, showcmd = vim.o.showcmd }
      vim.o.laststatus = 0
      vim.o.cmdheight = 0
      vim.o.ruler = false
      vim.o.showcmd = false
      vim.api.nvim_create_autocmd('BufLeave', {
        group = chrome,
        buffer = event.buf,
        once = true,
        callback = function()
          for name, value in pairs(saved) do vim.o[name] = value end
        end,
      })
    end,
  })

  -- See `:help telescope.builtin`
  local builtin = require 'telescope.builtin'
  vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = 'Files' })
  vim.keymap.set('n', '<leader>sm', builtin.git_status, { desc = 'Modified files' })
  vim.keymap.set('n', '<leader>su', function()
    builtin.git_files {
      cwd = vim.fn.getcwd(),
      git_command = { 'git', 'diff', '--name-only', '-z', '--' },
      split_char = '\0',
      prompt_title = 'Unstaged files',
    }
  end, { desc = 'Unstaged files' })
  vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = 'Grep' })
  vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = 'Current word' })
  vim.keymap.set('x', '<leader>sw', builtin.grep_string, { desc = 'Selected text' })
  vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = 'Keymaps' })
  vim.keymap.set('n', '<leader>sr', builtin.oldfiles, { desc = 'Recent files' })
  vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = 'Commands' })
  vim.keymap.set('n', '<leader>so', builtin.buffers, { desc = 'Open buffers' })

  require('which-key').add {
    { '<leader>sf', icon = { icon = '󰈔', color = 'blue' } },
    { '<leader>sm', icon = { icon = '', color = 'orange' } },
    { '<leader>su', icon = { icon = '', color = 'orange' } },
    { '<leader>sg', icon = { icon = '', color = 'green' } },
    { '<leader>sw', icon = { icon = '󰦨', color = 'green' }, mode = { 'n', 'x' } },
    { '<leader>sk', icon = { icon = '', color = 'purple' } },
    { '<leader>sr', icon = { icon = '󰋚', color = 'cyan' } },
    { '<leader>sc', icon = { icon = '', color = 'yellow' } },
    { '<leader>/', icon = { icon = '', color = 'green' } },
    { '<leader>so', icon = { icon = '', color = 'green' } },
  }

  -- Add Telescope-based LSP pickers when an LSP attaches to a buffer.
  -- If you later switch picker plugins, this is where to update these mappings.
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
    callback = function(event)
      local buf = event.buf

      -- Find references for the word under your cursor.
      vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })

      -- Jump to the implementation of the word under your cursor.
      -- Useful when your language has ways of declaring types without an actual implementation.
      vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })

      -- Jump to the definition of the word under your cursor.
      -- This is where a variable was first declared, or where a function is defined, etc.
      -- To jump back, press <C-t>.
      vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })

      -- Fuzzy find all the symbols in your current document.
      -- Symbols are things like variables, functions, types, etc.
      vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })

      -- Fuzzy find all the symbols in your current workspace.
      -- Similar to document symbols, except searches over your entire project.
      vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })

      -- Jump to the type of the word under your cursor.
      -- Useful when you're not sure what type a variable is and you want to see
      -- the definition of its *type*, not where it was *defined*.
      vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
    end,
  })

  -- Override default behavior and theme when searching
  vim.keymap.set('n', '<leader>/', function()
    -- You can pass additional configuration to Telescope to change the theme, layout, etc.
    builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
      winblend = 10,
    })
  end, { desc = 'Forward search' })
end
