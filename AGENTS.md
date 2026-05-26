# Repository Guidelines

## Project Structure & Module Organization

This repository currently contains personal dotfiles with a small root-level layout:

- `.bashrc`: repository-managed Bash settings sourced from the user's `~/.bashrc` via `init.sh`.
- `.tmux.conf`: tmux configuration, key bindings, pane behavior, mouse support, colors, and status-line settings.
- `.config/mise/config.global.toml`: repository-managed source for the global mise tool configuration for Rust, Go, Node.js, GitHub CLI, uv, and common CLI utilities. `init.sh` links this file to `~/.config/mise/config.toml` so the repo itself does not act as a local mise project. Docker is intentionally managed outside mise.
- `compose.yaml`: interactive Ubuntu container for manually testing `init.sh` from a fresh environment.
- `init.sh`: the only setup entrypoint. It links tracked dotfiles into `$HOME`, links the repository-managed Bash config into `$HOME/.config/dotfiles/bashrc`, updates the source block in `$HOME/.bashrc`, and invokes internal setup scripts.
- `script/`: internal setup helpers used by `init.sh`, including bashrc and mise setup. Do not add root-level setup scripts.
- `.agents/` and `.codex/`: local agent/config directories. Keep generated or machine-specific state out of versioned files unless it is intentionally shared.

Place future dotfiles at the repository root using their installed names, for example `.vimrc`, `.zshrc`, or `.config/<tool>/config`. If a tool needs several files, prefer a dedicated subdirectory that mirrors its target path.

## Build, Test, and Development Commands

There is no build step for this repository. Useful validation commands are:

- `git status --short`: check pending changes before editing or committing.
- `./init.sh`: install dotfile symlinks, update the managed source block in `$HOME/.bashrc`, and install/update mise-managed development tools.
- `./init.sh --links-only`: install dotfile symlinks without touching `$HOME/.bashrc` or running mise setup.
- `docker compose run --rm ubuntu`: start a fresh Ubuntu 26.04 container with a writable repo copy for interactive `./init.sh` testing.
- `tmux source-file ~/.tmux.conf`: reload the installed tmux config in an existing tmux session.
- `tmux -f .tmux.conf new-session -d -s dotfiles-check`: parse this repository's tmux config in a detached session.
- `tmux kill-session -t dotfiles-check`: remove the validation session after testing.

When adding new tool configs, document any required setup commands near the relevant files or in this guide.

## Coding Style & Naming Conventions

Keep dotfiles readable and grouped by feature. For tmux settings, use one directive per line, keep related bindings together, and add short comments for non-obvious behavior. Existing comments include Japanese and English; either is acceptable, but keep wording concise and consistent within a section.

Use lowercase, tool-native filenames and preserve leading dots for files installed into `$HOME`.

## Testing Guidelines

Validate syntax before committing. For `.tmux.conf`, start a temporary tmux session with `tmux -f .tmux.conf new-session -d -s dotfiles-check` and check for parse errors. If changing key bindings, test the affected prefix and pane/window commands interactively in tmux.

There is no automated test suite or coverage requirement at this time.

## Commit & Pull Request Guidelines

This repository has no commit history yet, so no local convention is established. Use short imperative commit subjects such as `Add tmux pane bindings` or `Document dotfile validation`.

Pull requests should include a concise description, the affected config files, validation performed, and any manual migration steps. Include screenshots only when changing visible UI such as status-line colors or prompts.

## Security & Configuration Tips

Do not commit secrets, host-specific tokens, private keys, or machine-local paths. Prefer examples with placeholders such as `<token>` or `$HOME`. Keep personal overrides in untracked local files when they should not apply to every machine.
