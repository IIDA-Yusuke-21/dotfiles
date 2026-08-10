# Neovim Core Plugins Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Telescope, Gitsigns, and the Neovim 0.12-compatible nvim-treesitter configuration to the existing lazy.nvim setup.

**Architecture:** Keep the current single-file Neovim configuration and replace the empty lazy.nvim specification with three plugin specifications. Telescope receives its required Plenary dependency; Gitsigns uses defaults; nvim-treesitter tracks its `main` branch, loads at startup, and runs `:TSUpdate` after updates.

**Tech Stack:** Neovim 0.12.4, Lua, lazy.nvim, Telescope, Plenary, Gitsigns, nvim-treesitter.

## Global Constraints

- Modify `.config/nvim/init.lua` only for the Neovim configuration change.
- Preserve all existing options, keymaps, and lazy.nvim bootstrap code.
- Use nvim-treesitter's `main` branch because this repository pins Neovim 0.12.4.
- Do not auto-install language parsers or add new keymaps in this change.
- Preserve all unrelated working-tree changes.
- Use a temporary `XDG_DATA_HOME` for verification so the user's normal Neovim data directory is not modified.

---

### Task 1: Add the three plugin specifications

**Files:**
- Modify: `.config/nvim/init.lua` at the existing `require("lazy").setup({})` call
- Test: headless Neovim commands with temporary data directories

**Interfaces:**
- Consumes: the existing lazy.nvim bootstrap and Neovim 0.12.4 runtime.
- Produces: lazy.nvim specifications for `nvim-telescope/telescope.nvim`, `lewis6991/gitsigns.nvim`, and `nvim-treesitter/nvim-treesitter`.

- [x] **Step 1: Run the pre-change configuration check**

Run:

```bash
rtk env XDG_DATA_HOME="$(mktemp -d)" nvim --headless "+lua assert(vim.g.mapleader == ' ')" "+lua assert(vim.opt.number:get())" +qa
```

Expected: exit code 0 with the current configuration loading successfully.

- [x] **Step 2: Replace the empty plugin specification**

Change only the empty setup call to:

```lua
require("lazy").setup({
  {
    "nvim-telescope/telescope.nvim",
    version = "*",
    dependencies = { "nvim-lua/plenary.nvim" },
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = {},
  },
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
  },
})
```

- [x] **Step 3: Verify configuration parsing and plugin specification loading**

Run:

```bash
rtk env XDG_DATA_HOME="$(mktemp -d)" nvim --headless "+lua assert(type(require('lazy')) == 'table')" "+lua assert(vim.g.mapleader == ' ')" "+lua assert(vim.opt.number:get())" +qa
```

Expected: exit code 0. lazy.nvim may clone the requested plugins into the temporary data directory.

- [x] **Step 4: Review only the intended diff and whitespace**

Run:

```bash
rtk git diff --check -- .config/nvim/init.lua
rtk git diff -- .config/nvim/init.lua
rtk git status --short
```

Expected: the Neovim diff contains only the plugin specification replacement; unrelated working-tree changes remain untouched.

- [x] **Step 5: Commit**

Do not commit unless the user explicitly requests it; report the verified working-tree state instead.
