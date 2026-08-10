# dotfiles

This is a personal dotfiles repository. `init.sh` links each managed config file into `$HOME` and sets up the required development tools.

## tmux

This repository uses [Oh my tmux!](https://github.com/gpakosz/.tmux) as a git submodule at `.tmux`.

- `$HOME/.tmux.conf` is linked to `.tmux/.tmux.conf`.
- `$HOME/.tmux.conf.local` is linked to `.tmux.conf.local`.
- Existing `$HOME/.tmux.conf` and `$HOME/.tmux.conf.local` files are moved to `.backup` with timestamped names before replacement.
- If `$HOME/.tmux.conf` is already an Oh my tmux! `.tmux/.tmux.conf` symlink, it is replaced without backup.

After cloning this repository, initialize the submodule before running `init.sh`:

```bash
git submodule update --init --recursive
```

## Trying It with Docker

You can test `init.sh` in a fresh environment on Docker. This is useful when you want to verify the setup without modifying your host `$HOME`.

### Prerequisites

- Docker Engine and `docker compose` must be available

### Start the Container

Run the following from the repository root:

```bash
docker compose run --rm ubuntu
```

The first run may take a little time because the container installs required packages with `apt-get`.

### What the Container Does

- Uses `ubuntu:26.04` as the base image
- Mounts the repository at `/repo` as read-only
- Creates a writable working copy at `/workspace/dotfiles`
- Starts the shell in `/workspace/dotfiles`

After startup, you can try:

```bash
git submodule update --init --recursive
./init.sh
source ~/.bashrc
mise doctor
```

If you only want to verify symlink creation, run:

```bash
./init.sh --links-only
```

If you update `.config/mise/global-config.toml` and only want to re-apply the mise configuration, run:

```bash
./sync-mise.sh
```

## Neovim

The repository includes a small, plugin-free starter configuration. It is linked to `$HOME/.config/nvim/init.lua` by `init.sh`, and Neovim is installed by mise.

After setup, start it with:

```bash
./init.sh
source ~/.bashrc
nvim
```

The space key is the leader key: `Space w` saves, `Space q` quits, and `Space e` opens the file explorer. Use `i` to insert text, `Esc` to return to normal mode, and `:Tutor` for the built-in tutorial. `Ctrl-h/j/k/l` moves between split windows.

Run `exit` when you are done. Because the command uses `--rm`, the container is removed automatically after it exits.
