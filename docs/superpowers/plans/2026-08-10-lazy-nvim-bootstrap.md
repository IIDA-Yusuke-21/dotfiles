# lazy.nvim Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (recommended) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bootstrap `folke/lazy.nvim` from the existing Neovim starter configuration without adding any actual plugins.

**Architecture:** Add a small bootstrap block at the top of `.config/nvim/init.lua`. It checks `vim.fn.stdpath("data") .. "/lazy/lazy.nvim"`, clones the stable branch only when missing, prepends the checkout to `runtimepath`, and initializes lazy.nvim with an empty specification.

**Tech Stack:** Neovim 0.12.4, Lua, Git, lazy.nvim stable branch.

## Global Constraints

- Modify only `.config/nvim/init.lua` during implementation.
- Do not add plugin specifications, themes, keymaps, or unrelated refactors.
- Keep existing editor options and mappings unchanged.
- Leave all pre-existing working-tree changes untouched.
- Use a temporary `XDG_DATA_HOME` during verification so tests do not alter the user's normal Neovim data directory.

---

### Task 1: Add and verify the lazy.nvim bootstrap

**Files:**
- Modify: `.config/nvim/init.lua:1`
- Test: headless Neovim commands using a temporary `XDG_DATA_HOME`

**Interfaces:**
- Consumes: Neovim's `vim.fn.stdpath`, `vim.uv`, `vim.fn.system`, and runtime path APIs.
- Produces: An initialized `lazy` module with an empty plugin specification.

- [ ] **Step 1: Run the pre-change baseline check**

Run:

```bash
XDG_DATA_HOME="$(mktemp -d)" nvim --headless +'lua assert(not pcall(require, "lazy"))' +qa
```

Expected: exit successfully because the plugin manager is not installed in the isolated data directory.

- [ ] **Step 2: Add the minimal bootstrap block**

Insert this block before the existing options and keymaps in `.config/nvim/init.lua`:

```lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit" },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({})
```

- [ ] **Step 3: Verify Lua parsing and initialization**

Run:

```bash
XDG_DATA_HOME="$(mktemp -d)" nvim --headless '+lua assert(type(require("lazy")) == "table")' +qa
```

Expected: exit code 0 after the isolated lazy.nvim checkout is cloned and loaded.

- [ ] **Step 4: Verify the existing configuration still loads**

Run:

```bash
XDG_DATA_HOME="$(mktemp -d)" nvim --headless '+lua assert(vim.g.mapleader == " ")' '+lua assert(vim.opt.number:get())' +qa
```

Expected: exit code 0, confirming the existing leader and line-number settings remain active.

- [ ] **Step 5: Review the diff and working tree**

Run:

```bash
git diff --check -- .config/nvim/init.lua
git diff -- .config/nvim/init.lua
git status --short
```

Expected: only the intended bootstrap block appears in the Neovim diff; pre-existing changes remain present and are not modified.

- [ ] **Step 6: Commit when repository permissions allow**

```bash
git add .config/nvim/init.lua
git commit -m "feat: bootstrap lazy.nvim"
```

If `.git/index` remains read-only, report that the implementation is verified but uncommitted.
