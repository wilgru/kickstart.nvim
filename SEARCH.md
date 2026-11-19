# Native search

Search uses a temporary tab with a file list on the left and a read-only preview
on the right. It uses your editor theme and the existing bottom input line.
The statusline mode pill reads **Search** throughout the session.

## Keys

- Type to filter; **Enter** finishes input and returns to the results.
- **j/k** select a result; **Enter** opens it in the original window.
- **i** edits the query again. **Ctrl-N/P** select results while typing.
- **Esc** while typing returns to results without discarding the query.
- **q/Esc** in results closes search and restores the original layout.
- **Tab** switches focus between the results and preview (for scrolling).

## Opening search

Press **s** to show the Which-key search popup, then another key to launch a
search. The former leader search shortcuts are removed. In Visual mode,
**sw** searches the selected text.

| Keys | Search |
| --- | --- |
| `sf` | Project files |
| `sm` | All modified files |
| `su` | Unstaged tracked files |
| `sg` | Live grep |
| `sw` | Current word / selected text |
| `s.` | Recent files |
| `sk` | Keymaps |
| `sc` | Commands |

The popup contains files, modified files (all Git changes), unstaged tracked
files, live grep, current word, recent files, commands, and keymaps.
File lists include hidden files and respect ignore files. Word and
selection search are literal; ordinary grep uses ripgrep regex and smart case.

Surround mappings are **ys** (add), **ds** (delete), and **cs** (change).
Additional surround tools use **gsf**, **gsF**, and **gsh**. Use **cl** for the
old Normal-mode `s` action (change a character and enter Insert mode).

LSP references, definitions, implementations, type definitions, and document /
workspace symbols use the same interface. Workspace symbols are fetched once,
then filtered locally. Native `vim.ui.select` remains in use for code actions.

File/name lists use Neovim's fuzzy matching. Grep is debounced and cancels obsolete
requests. Lists display up to 1,000 results; refine the query for larger projects.
Subprocess output is bounded at 8 MiB. Binary files and files larger than 1 MiB
aren't previewed. Preview buffers aren't added to the listed buffers or attached
to LSP clients. The current file's unsaved content is used when already loaded.

Requires `fd`, `rg`, and Git. No search plugin is required; fzf was uninstalled.
Telescope's old configuration remains disabled in `lua/plugins/telescope.lua`.

Implementation: `lua/config/search.lua` (UI),
`lua/config/search_sources.lua` (providers), and `lua/plugins/search.lua` (keys).

## Tests

```sh
nvim --headless '+lua dofile("tests/native_search.lua")' +qa!
nvim --headless '+lua dofile("tests/native_search_input.lua")' +qa!
```
