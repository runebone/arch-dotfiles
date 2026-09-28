# Navigation and Go workflow

Leader is **Space**. Restart Neovim after changing configuration.

## Search

| Shortcut | Action |
| --- | --- |
| `Ctrl P`, `Space pf` | Find project files |
| `Space rg` | Search project text; visual mode starts from the selection |
| `Space ps` | Prompt for text, then show project matches |
| `Space j` | Files containing the cursor word; type to filter paths, `Ctrl E` edits the text |
| `Space sf` | Fuzzy path → Enter locks matching files → fuzzy text; `Ctrl B` revises the path and preserves text; `Ctrl F` toggles literal/fuzzy text |
| `Space sm` | Choose an explicit directory and search it, including ignored files |
| `Space /` | Fuzzy search inside the current buffer |
| `Space sr` | Resume the previous Telescope picker |
| `Space b` | Switch buffers, most recently used first |

Project searches use the current file's nearest Git root, or the directory shown in Oil. For other buffers they use the working directory's Git root. Without Git they use the working directory. Linked worktrees and submodules are supported. Picker titles show the scope. An explicitly supplied `cwd` is preserved.

In `Space sf`, both literal and fuzzy text modes are case-insensitive. The title shows the mode; it is preserved while revising the path filter. New searches start in fuzzy mode.

Ripgrep searches respect `.gitignore`, `.ignore`, and `.rgignore`. Put `/docs/` or `/migrations/` in a project-root `.ignore` to hide those directories. `Space sm` overrides ignore rules only within the chosen directory; its relative paths and directory completion use the working directory. It remembers the last directory for that cwd during the session. Hidden files are still excluded.

## Follow code

| Shortcut | Action |
| --- | --- |
| `gd` / `go` | Definition / type definition |
| `gr` | References with Telescope previews |
| `gi` | Implementations with Telescope previews |
| `Space ci` / `Space co` | Incoming / outgoing calls |
| `Space cu` | References to all methods of a Go interface, including embedded interfaces |
| `Space ss` / `Space sw` | Current-file / workspace symbols |
| `Ctrl O` / `Ctrl I` | Back / forward through jump locations |
| `Space a`, `Space 1`–`9` | Pin a file with Harpoon / jump to a pinned file |

`Space cu` uses gopls and the Go Treesitter parser. Its results are semantic method references, not instance-specific data flow. It supports ordinary embedded and aliased interfaces; generic type-set constraints are not supported. Results follow gopls's active build configuration. Type paths or text to filter the combined results.

## Refactor task list

Collect locations while reading code, then browse and complete them. Tasks are saved
automatically per Git root (working directory outside Git) in Neovim's local state
directory, under `refactor/`; no task files are added to your repository.

| Shortcut | Action |
| --- | --- |
| `Space qa`, `Ctrl Q` (Normal mode) | Add the current line; adding it again reopens the existing task |
| `Space qn` | Add the current line with a note, or update its existing note |
| `Space qq` | Telescope pending tasks, with source previews |
| `Space qf` | Export pending tasks to quickfix and open it |
| `Space qd` | Complete the task at the cursor, in source or the exported quickfix list |
| `]q` / `[q` | Next / previous entry in the active quickfix list |
| `Space ql` | Diagnostics to location list (previously `Space q`) |

In the task picker, `Enter` jumps to the source, `Ctrl D` toggles completion,
`Ctrl X` deletes the selected task, and `Ctrl A` switches between pending and all
tasks. These actions work in Insert and Normal modes. Show all tasks to reopen
completed work. Multiple lines in the same file are independent tasks.

Completion/deletion also updates the exported task quickfix list. Running tests
or other searches can change the active quickfix list without losing your tasks;
use `Space qf` to export them again. Harpoon remains available for pinned files.

Locations follow edits while their buffers are loaded. After reopening a file,
an exact, unique source-line match can relocate a task; otherwise its saved line
number is used (clamped to the file length). File renames are not tracked.
Concurrent Neovim sessions for the same project use the last saved task snapshot.
`Ctrl V` still enters Visual Block mode. If your terminal intercepts `Ctrl Q`,
use `Space qa`, or disable terminal flow control with `stty -ixon` in that shell.

## Edit

| Shortcut | Action |
| --- | --- |
| `cif` / `vaf` | Change function body / select whole function |
| `cia` / `daa` | Change argument / delete argument with separator |
| `Space rn` | Rename symbol |
| `Space ca` | Code actions and refactorings |
| `Space oi` | Organize Go imports |
| `Space cl` | Run a code lens |
| `Ctrl S`, then `;` / `,` | Next / previous snippet placeholder |

Undo history persists across restarts.

## Go tasks

| Shortcut | Action |
| --- | --- |
| `Space x` in Go | Run the current **package**; it must be a `main` package |
| `Space ta` in Go | Switch `foo.go` ↔ `foo_test.go`; missing counterparts are not created |
| `Space tn` | Run the enclosing `Test…` function, including its subtests |
| `Space tp` | Run tests for the current package |
| `Space tr` | Rerun the last Go task, also available in terminal Normal mode |
| `Space tq` | Open failure locations in quickfix |
| `]q` / `[q` | Next / previous quickfix entry |
| `Space rl` in Go | Run golangci-lint for the current package |
| `Space rf` in Go | Run `go mod tidy` asynchronously |

Go tasks resolve the nearest `go.mod` independently of search scope. They save the current source buffer, run in a reusable terminal, and collect file/line failures into quickfix when finished. Other modified buffers are not saved automatically. Tests use `-count=1`; integration build tags are not added (Go still respects your environment, including `GOFLAGS`). Nearest-test selection runs the parent test function, not just one subtest. Use `Ctrl C` in the task terminal to stop a running command; `Esc Esc` returns to Normal mode. Full linting is manual; gopls still supplies live diagnostics.

## Regression checks

Run from a shell:

```sh
bash tests/run.sh
```

Requires Neovim, ripgrep, Go (1.23+), gopls, the Go Treesitter parser, and the Telescope/Plenary/fzf plugins already installed in Neovim's normal data directory. The suite installs nothing and disables Go dependency downloads. It uses temporary fixtures and temporary cache/state directories; it does not execute commands in your work repository.

The checks cover Git-root selection, worktree markers, picker scope, large batched searches, query preservation, actual gopls interface references, and real Go test execution/failure navigation.
