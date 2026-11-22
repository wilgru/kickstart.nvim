# Editor keys and native search

Keep native Vim editing on letter keys; use **Space** for project tools and
menus. Your leader is Space.

| Prefix | Purpose |
| --- | --- |
| `g` | Native Vim navigation and LSP go-to commands |
| `c` | Native change operator: `cw`, `ciw`, `ci"`, `cc`, etc. |
| `s` | Native substitute: delete a character and enter Insert mode |
| `Space c` | Code-changing operations |
| `Space l` | Language suggestions: fixes and refactorings from the LSP |
| `Space s` | Search |
| `Space g` | Git |
| `Space t` | Toggles |
| `Space i` | Inspect |
| `Space f` | Toggle Fyler (also closes it from inside the explorer) |
| `Space o` | Open the link under the cursor externally |

The experimental bare-`s` search popup, Space-a actions, and Space-g navigation
remappings have been removed. Native `g` commands are no longer disabled.

The leader popup is context-aware. Unsupported language tools, unavailable
formatters, Git commands outside Git-attached buffers, editing operations in
read-only/special buffers, and empty diagnostics/history options are hidden.
Code lens is shown only on a line with a lens; hunk actions require local changes.
Empty submenu headings disappear too. File browsing and project file search
remain available everywhere.

**Space o** appears only over a URL, an inline Markdown link, or an extmark-based
rendered hyperlink. Plain filesystem paths and arbitrary words don't qualify.
Relative Markdown links resolve beside the source document. Link checks don't
make synchronous language-server requests, and the shortcut won't open anything
if invoked away from a link. Native `gx` retains its original behavior.

## Code operations: Space c

These perform operations on existing code, unlike native `c`, which replaces
text and enters Insert mode.

| Key | Operation |
| --- | --- |
| `r` | Rename symbol |
| `l` | Run code lens |
| `f` | Format buffer / selection through the existing Conform setup |

**Space l** opens contextual language suggestions in Normal or Visual mode;
it replaces Space ca with no duplicate binding. Suggestions can include fixes,
imports, and refactorings, depending on the language server and selection.

Direct editing stays on native `gu`, `gU`, `gq`, `gw`, and `gJ`, rather than
duplicated leader aliases. Surroundings use `ys` (add), `ds`
(delete), and `cs` (change); for example, `ysiw)` surrounds a word.

## Go to: g

Native movement such as `gg`, `gf`, `gt`, `gi`, and `g;` works normally.
In LSP-enabled buffers:

| Keys | Destination |
| --- | --- |
| `gd` | Definition |
| `gD` | Declaration |
| `grr` | References |
| `gri` | Implementation |
| `grt` | Type definition |
| `gO` | Document symbols |
| `gW` | Workspace symbols |

These use the native search interface where appropriate. Workspace symbols are
fetched once and filtered locally. `g[` / `g]` move to text-object boundaries;
`gsf` / `gsF` navigate surroundings, with the usual `l`/`n` suffixes.

## Search: Space s

| Key | Search |
| --- | --- |
| `f` | Project files |
| `m` | All Git changes: staged, unstaged, deleted, and untracked |
| `u` | Unstaged tracked files only |
| `g` | Live grep |
| `w` | Current word / Visual selection |
| `c` | Commands |
| `k` | Keymaps |
| `.` | Recent files |

Search opens a temporary tab with a file list and a syntax-highlighted,
read-only preview. It uses your editor theme, a transparent background, no `~`
markers, and the native bottom input line with no prompt label. The shared
statusline shows **Search** and the search type, not a filename.

- Type to filter live. Enter finishes input and returns to the results.
- `j`/`k` select a result; Enter opens it in the original window.
- `i` edits the query again. Ctrl-N/P select results while typing.
- Esc while typing returns to results without discarding the query.
- `q`/Esc in results closes search and restores the original layout.
- Tab switches between results and preview for scrolling.

File lists use Neovim fuzzy matching, include hidden files, and respect ignore
files. Grep uses ripgrep regex and smart case; word/selection search is literal.
Lists show at most 1,000 results. Grep is debounced, obsolete processes are
cancelled, and subprocess output is bounded at 8 MiB. Binary files and files
larger than 1 MiB aren't previewed. Loaded files preview their unsaved contents.
Preview buffers aren't listed or attached to language servers.

Requires `fd`, `rg`, and Git. No search plugin is required. fzf was uninstalled;
Telescope remains disabled in `lua/plugins/telescope.lua`. Native `vim.ui.select`
is used for code-action prompts.

## Git: Space g

| Key | Action |
| --- | --- |
| `s` / `r` | Stage / reset hunk (also works on Visual selections) |
| `S` / `R` | Stage / reset buffer |
| `p` / `i` | Preview hunk in a popup / inline |
| `b` | Blame current line |
| `d` / `D` | Diff against index / HEAD |
| `q` / `Q` | Hunk quickfix list for file / repository |

Git shortcuts appear in Git-attached buffers. `[c` / `]c` still navigate changes.
The old Space-h Git shortcuts are removed.

## Toggles and inspection

**Space t**: `c{motion}` / `cc` toggle comments, `~{motion}` / `~~` toggle case,
`b` toggle Git line blame, `w` toggle Git word diff, and `h` toggle LSP inlay
hints when supported. Visual `Space tc` / `Space t~` work on the selection.
Native `gc`, `gcc`, and `g~` remain available.

**Space i**: `a` character codes, `8` UTF-8 bytes, `s` highlight surroundings
(`sl` previous, `sn` next).

## Implementation and tests

`lua/config/search.lua` owns the search UI; `lua/config/search_sources.lua`
contains providers. `lua/plugins/search.lua` registers search and LSP shortcuts.
`lua/config/actions.lua` registers the code/inspection menus;
`lua/config/context.lua` filters popup entries and detects links.

```sh
sh tests/run.sh
# Or run one suite:
sh tests/run.sh tests/action_keymaps.lua
# Context-aware visibility and link detection:
sh tests/run.sh tests/context_menu.lua
```

Each suite runs in an isolated Neovim process without swap or ShaDa writes.
Assertion failures and Neovim errors exit nonzero; the runner stops at the first
failed suite.
