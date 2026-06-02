# Repository Guidelines

## Project Structure & Module Organization

This repository currently contains personal dotfiles with a small root-level layout:

- `.bashrc`: repository-managed Bash settings sourced from the user's `~/.bashrc` via `init.sh`.
- `.tmux/`: git submodule for [Oh my tmux!](https://github.com/gpakosz/.tmux). The upstream `.tmux/.tmux.conf` is linked into `$HOME/.tmux.conf` and must not be edited directly.
- `.tmux.conf.local`: repository-managed Oh my tmux! customization file linked into `$HOME/.tmux.conf.local`. It currently mirrors the upstream sample; migrate personal bindings here instead of editing `.tmux/.tmux.conf`.
- `.backup/`: timestamped backups created by setup scripts before replacing existing client-side dotfiles. Keep actual backup contents untracked.
- `.config/mise/global-config.toml`: repository-managed source for the global mise tool configuration for Rust, Go, Node.js, GitHub CLI, uv, and common CLI utilities. Root-level setup entrypoints link this file to `~/.config/mise/config.toml` so the repo itself does not act as a local mise project. Docker is intentionally managed outside mise.
- `compose.yaml`: interactive Ubuntu container for manually testing `init.sh` from a fresh environment.
- `init.sh`: the primary bootstrap entrypoint. It links tracked dotfiles into `$HOME`, links the repository-managed Bash config into `$HOME/.config/dotfiles/bashrc`, configures Oh my tmux!, updates the source block in `$HOME/.bashrc`, and invokes internal setup scripts.
- `sync-mise.sh`: focused mise entrypoint that links the repository-managed mise config and reapplies mise-managed tool installation.
- `script/`: internal setup helpers used by root-level entrypoints, including bashrc and mise setup.
- `.agents/` and `.codex/`: local agent/config directories. Keep generated or machine-specific state out of versioned files unless it is intentionally shared.

Place future dotfiles at the repository root using their installed names, for example `.vimrc`, `.zshrc`, or `.config/<tool>/config`. If a tool needs several files, prefer a dedicated subdirectory that mirrors its target path.

## Build, Test, and Development Commands

There is no build step for this repository. Useful validation commands are:

- `git status --short`: check pending changes before editing or committing.
- `git submodule update --init --recursive`: initialize the Oh my tmux! submodule after cloning.
- `./init.sh`: install dotfile symlinks, update the managed source block in `$HOME/.bashrc`, and install/update mise-managed development tools.
- `./init.sh --links-only`: install dotfile symlinks without touching `$HOME/.bashrc` or running mise setup.
- `./sync-mise.sh`: link the repository-managed mise config into `$HOME` and re-apply mise-managed development tools after editing `.config/mise/global-config.toml`.
- `docker compose run --rm ubuntu`: start a fresh Ubuntu 26.04 container with a writable repo copy for interactive `./init.sh` testing.
- `tmux source-file ~/.tmux.conf`: reload the installed tmux config in an existing tmux session.
- `tmux -f "$HOME/.tmux.conf" new-session -d -s dotfiles-check`: parse the installed tmux config in a detached session.
- `tmux kill-session -t dotfiles-check`: remove the validation session after testing.

When adding new tool configs, document any required setup commands near the relevant files or in this guide.

## Coding Style & Naming Conventions

Keep dotfiles readable and grouped by feature. For tmux settings, edit `.tmux.conf.local`, use one directive per line, keep related bindings together, and add short comments for non-obvious behavior. Existing comments include Japanese and English; either is acceptable, but keep wording concise and consistent within a section.

Use lowercase, tool-native filenames and preserve leading dots for files installed into `$HOME`.

## tmux / Oh my tmux Notes

- Keep upstream `.tmux/.tmux.conf` untouched. Put personal tmux settings in `.tmux.conf.local`.
- Oh my tmux applies generated settings after sourcing `.tmux.conf.local`; add `#!important` to `set`, `bind`, and `unbind` lines that must win after that pass.
- Upstream enables `Ctrl-a` as a secondary prefix with `prefix2 C-a`. Disable it with `set -gu prefix2 #!important`; setting only `prefix C-space` does not disable `Ctrl-a`.
- Use tmux key names `M-h`, `M-j`, `M-k`, and `M-l` for `Alt+h/j/k/l`. On tmux 3.6b, `S-h` and `S-l` are valid for `Shift+h/l`.
- When validating tmux from inside an existing tmux session, unset inherited tmux variables: `TMUX`, `TMUX_PANE`, `TMUX_CONF`, `TMUX_CONF_LOCAL`, `TMUX_PROGRAM`, and `TMUX_SOCKET`. Otherwise Oh my tmux may resolve `TMUX_CONF_LOCAL` to the real `$HOME` instead of the test `$HOME`.
- For non-destructive validation, use a temporary `HOME` plus `DOTFILES_BACKUP_DIR`, then start tmux with `-L <test-socket>` and clean up with `tmux -L <test-socket> kill-server`.

## Testing Guidelines

Validate syntax before committing. For tmux changes, run `./init.sh --links-only`, then start a temporary tmux session with `tmux -f "$HOME/.tmux.conf" new-session -d -s dotfiles-check` and check for parse errors. If changing key bindings, test the affected prefix and pane/window commands interactively in tmux.

There is no automated test suite or coverage requirement at this time.

## Commit & Pull Request Guidelines

This repository has no commit history yet, so no local convention is established. Use short imperative commit subjects such as `Add tmux pane bindings` or `Document dotfile validation`.

Pull requests should include a concise description, the affected config files, validation performed, and any manual migration steps. Include screenshots only when changing visible UI such as status-line colors or prompts.

## Security & Configuration Tips

Do not commit secrets, host-specific tokens, private keys, or machine-local paths. Prefer examples with placeholders such as `<token>` or `$HOME`. Keep personal overrides in untracked local files when they should not apply to every machine.
