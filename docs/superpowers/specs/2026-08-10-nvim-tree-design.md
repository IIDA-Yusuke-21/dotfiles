# nvim-tree Integration Design

## Goal

Add `nvim-tree/nvim-tree.lua` with file icons and make the existing `<leader>e` file-explorer mapping open and close nvim-tree.

## Design

The existing `require("lazy").setup({...})` list will receive one plugin specification for `nvim-tree/nvim-tree.lua`, with `nvim-tree/nvim-web-devicons` as its dependency and default options via `opts = {}`. The existing normal-mode `<leader>e` mapping will change from `:Explore` to `:NvimTreeToggle`.

No other plugin specifications, options, keymaps, netrw settings, or unrelated working-tree changes will be modified. The existing Telescope duplicate specification and markview specification are intentionally preserved.

## Verification

Use a temporary XDG config/data/state/cache environment so lazy.nvim can write its lockfile without touching the user's normal configuration. Confirm Neovim loads, lazy.nvim recognizes nvim-tree and web-devicons, the `NvimTreeToggle` command exists, and `<leader>e` is mapped to it. Review the configuration diff and whitespace.
