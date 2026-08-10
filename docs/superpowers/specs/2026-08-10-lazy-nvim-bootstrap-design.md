# lazy.nvim Bootstrap Design

## Goal

Add `lazy.nvim` as Neovim's plugin manager without installing any actual Neovim plugins yet.

## Context

The repository currently has a single, intentionally small plugin-free configuration at `.config/nvim/init.lua`. Neovim is pinned to version 0.12.4 by mise. Existing keymaps and editor options must remain unchanged.

## Design

The configuration will bootstrap `folke/lazy.nvim` from its stable release branch under `vim.fn.stdpath("data") .. "/lazy/lazy.nvim"`. If the directory is missing, Neovim will clone it once; otherwise the existing checkout will be reused. The runtime path will then prepend that directory and call `require("lazy").setup({})` with an empty plugin specification.

The bootstrap code will be placed near the top of `.config/nvim/init.lua`, before options and keymaps. No plugin specifications, theme changes, keymaps, or unrelated refactoring will be added.

## Error handling

If the initial clone fails, Neovim will stop with an actionable error instead of silently continuing with a partially configured plugin manager. Subsequent starts will not clone again when the checkout already exists.

## Verification

- Confirm the Lua file parses with Neovim's headless mode.
- Start Neovim headlessly and confirm `require("lazy")` loads and the empty setup completes.
- Confirm the existing repository changes remain untouched.

## Scope

Only `.config/nvim/init.lua` is an implementation target. This design document records the approved approach; no other Neovim plugins are part of this change.
