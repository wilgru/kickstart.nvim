# Editor keys and Telescope

Keep native Vim editing on letter keys; use **Space** for project tools and
menus. Your leader is Space.

| Prefix | Purpose |
| --- | --- |
| `g` | Native Vim navigation and LSP go-to commands |
| `c` | Native change operator: `cw`, `ciw`, `ci"`, `cc`, etc. |
| `s` | Native substitute: delete a character and enter Insert mode |
| `Space c` | Code-changing operations |
| `Space l` | Language suggestions: fixes and refactorings from the LSP |
| `Space s` | Telescope search |
| `Space /` | Forward search (fuzzy search in the current buffer) |
| `Space g` | Git |
| `Space t` | Toggles |
| `Space i` | Inspect |
| `Space d` | Diagnostics for the current buffer |
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
| `grd` | Definition |
| `gD` | Declaration |
| `grr` | References |
| `gri` | Implementation |
| `grt` | Type definition |
| `gO` | Document symbols |
| `gW` | Workspace symbols |

These use Telescope pickers where appropriate. `g[` / `g]` move to text-object boundaries;
`gsf` / `gsF` navigate surroundings, with the usual `l`/`n` suffixes.

## Telescope search: Space s

| Key | Search |
| --- | --- |
| `f` | Project files |
| `m` | Modified files (Git status) |
| `u` | Unstaged tracked files |
| `g` | Live grep |
| `o` | Open buffers |
| `w` | Current word / Visual selection |
| `c` | Commands |
| `k` | Keymaps |
| `r` | Recent files |

In a picker, `Ctrl-/` (Insert mode) or `?` (Normal mode) shows available keys.
Grep pickers require `rg`. Telescope also provides `vim.ui.select` prompts,
including code actions, when its `ui-select` extension is available.

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

`lua/plugins/telescope.lua` sets up Telescope and registers search and LSP picker shortcuts.
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
