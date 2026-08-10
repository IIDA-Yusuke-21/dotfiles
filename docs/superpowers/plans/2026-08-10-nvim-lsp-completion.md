# Neovim LSP and Completion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add mise-managed Python, Rust, and Markdown language servers plus blink.cmp code, snippet, and path completion to the existing Neovim 0.12.4 configuration.

**Architecture:** Keep the single-file Neovim configuration and existing lazy.nvim bootstrap. Add blink.cmp v1 for completion sources, nvim-lspconfig for server-specific config data, and Neovim's standard `vim.lsp.config` / `vim.lsp.enable` APIs for activation. Install `pyright`, `rust-analyzer`, and `marksman` through exact mise pins.

**Tech Stack:** Neovim 0.12.4, Lua, lazy.nvim, blink.cmp v1, friendly-snippets, nvim-lspconfig, mise, Pyright, rust-analyzer, Marksman.

## Global Constraints

- Manage all three external LSP servers through `.config/mise/global-config.toml`; do not add Mason.
- Use exact pins: `npm:pyright = "1.1.411"`, `rust-analyzer = "2026-08-03"`, and `marksman = "2026-02-08"`.
- Use blink.cmp's stable v1 line with `version = "1.*"`; do not use its active v2 line.
- Use `vim.lsp.config` and `vim.lsp.enable`; do not call the deprecated `require("lspconfig").<server>.setup()` API.
- Preserve the existing lazy.nvim bootstrap, plugins, options, mappings, autocmds, and behavior unless this plan explicitly extends them.
- Do not add format-on-save, lint-on-save, debugging, AI completion, or project-local language configuration.
- Use temporary XDG directories for headless Neovim verification.
- Do not commit implementation changes unless the user explicitly requests a commit.

---

### Task 1: Add reproducible language-server pins

**Files:**
- Modify: `.config/mise/global-config.toml` in the `[tools]` table
- Test: mise config and remote-version resolution commands

**Interfaces:**
- Consumes: the existing exact-version mise policy and Node/Rust runtimes.
- Produces: `pyright`, `rust-analyzer`, and `marksman` executables on the mise-managed PATH.

- [x] **Step 1: Record the pre-change mise state**

Run:

```bash
rtk mise config ls --json
rtk mise ls --json
```

Expected: the repository-linked global config is listed, and no newly requested LSP pins are present yet.

- [x] **Step 2: Add the exact language-server entries**

Add these entries to `[tools]`, preserving the existing order and pins:

```toml
"npm:pyright" = "1.1.411"
marksman = "2026-02-08"
rust-analyzer = "2026-08-03"
```

- [x] **Step 3: Verify the configured versions resolve**

Run:

```bash
rtk mise ls-remote npm:pyright
rtk mise ls-remote marksman
rtk mise ls-remote rust-analyzer
```

Expected: the output contains `1.1.411`, `2026-02-08`, and `2026-08-03`, respectively; no configuration parse error occurs.

### Task 2: Add blink.cmp and snippet completion

**Files:**
- Modify: `.config/nvim/init.lua` in the existing `require("lazy").setup({ ... })` plugin list
- Test: isolated headless Neovim startup and plugin registration assertions

**Interfaces:**
- Consumes: the existing lazy.nvim bootstrap and the Neovim 0.12.4 runtime.
- Produces: a configured `blink.cmp` instance with the `lsp`, `path`, `snippets`, and `buffer` sources and default completion keymaps.

- [x] **Step 1: Run the pre-change headless configuration check**

Copy the current configuration into a temporary XDG config directory and run Neovim with temporary data/state/cache directories:

```bash
rtk mkdir -p /tmp/codex-nvim-lsp-config
rtk cp -a .config/nvim/. /tmp/codex-nvim-lsp-config/nvim
rtk env XDG_CONFIG_HOME=/tmp/codex-nvim-lsp-config XDG_DATA_HOME=/tmp/codex-nvim-lsp-data XDG_STATE_HOME=/tmp/codex-nvim-lsp-state XDG_CACHE_HOME=/tmp/codex-nvim-lsp-cache /home/iida/.local/share/mise/installs/neovim/0.12.4/bin/nvim --headless "+lua assert(vim.g.mapleader == ' ')" "+lua assert(vim.opt.number:get())" +qa
```

Expected: exit code 0 with the current configuration.

- [x] **Step 2: Add the blink.cmp plugin specification**

Insert this specification into the lazy.nvim plugin list:

```lua
  {
    "saghen/blink.cmp",
    version = "1.*",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = { preset = "default" },
      appearance = { nerd_font_variant = "mono" },
      completion = { documentation = { auto_show = false } },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
  },
```

- [x] **Step 3: Verify blink.cmp loads and existing settings remain intact**

Run the copied configuration with temporary XDG directories:

```bash
rtk env XDG_CONFIG_HOME=/tmp/codex-nvim-lsp-config XDG_DATA_HOME=/tmp/codex-nvim-lsp-data XDG_STATE_HOME=/tmp/codex-nvim-lsp-state XDG_CACHE_HOME=/tmp/codex-nvim-lsp-cache /home/iida/.local/share/mise/installs/neovim/0.12.4/bin/nvim --headless "+lua assert(type(require('blink.cmp')) == 'table')" "+lua assert(vim.fn.exists(':BlinkCmp') == 2)" "+lua assert(vim.g.mapleader == ' ')" "+lua assert(vim.opt.number:get())" +qa
```

Expected: exit code 0 after lazy.nvim installs blink.cmp and friendly-snippets into the temporary data directory.

### Task 3: Configure Python, Rust, and Markdown LSPs

**Files:**
- Modify: `.config/nvim/init.lua` after the plugin specifications and in the options/configuration section
- Test: isolated headless Neovim LSP configuration assertions

**Interfaces:**
- Consumes: the blink.cmp plugin from Task 2 and nvim-lspconfig's `lsp/` server definitions.
- Produces: enabled `pyright`, `rust_analyzer`, and `marksman` configurations with blink capabilities and buffer-local LSP mappings.

- [x] **Step 1: Add the nvim-lspconfig plugin specification**

Insert this specification into the lazy.nvim plugin list:

```lua
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "saghen/blink.cmp" },
    config = function()
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      for _, server in ipairs({ "pyright", "rust_analyzer", "marksman" }) do
        vim.lsp.enable(server)
      end
    end,
  },
```

- [x] **Step 2: Add shared LSP mappings through `LspAttach`**

Add this after the plugin specifications so it composes with each server's own `on_attach` callback:

```lua
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    local function bufmap(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
    end

    bufmap("n", "gd", vim.lsp.buf.definition, "Go to definition")
    bufmap("n", "K", vim.lsp.buf.hover, "Show documentation")
    bufmap("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
    bufmap({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
  end,
})
```

- [x] **Step 3: Configure diagnostics without changing existing editor defaults**

Add this after the existing editor option declarations:

```lua
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})
```

- [x] **Step 4: Verify all three server configurations enable cleanly**

Run:

```bash
rtk env XDG_CONFIG_HOME=/tmp/codex-nvim-lsp-config XDG_DATA_HOME=/tmp/codex-nvim-lsp-data XDG_STATE_HOME=/tmp/codex-nvim-lsp-state XDG_CACHE_HOME=/tmp/codex-nvim-lsp-cache /home/iida/.local/share/mise/installs/neovim/0.12.4/bin/nvim --headless /tmp/codex-nvim-lsp-sample.py "+lua assert(vim.lsp.config['pyright'])" "+lua assert(vim.lsp.config['rust_analyzer'])" "+lua assert(vim.lsp.config['marksman'])" "+lua assert(vim.lsp.is_enabled('pyright'))" "+lua assert(vim.lsp.is_enabled('rust_analyzer'))" "+lua assert(vim.lsp.is_enabled('marksman'))" "+lua assert(vim.g.mapleader == ' ')" "+lua assert(vim.opt.number:get())" +qa
```

Expected: exit code 0 with no deprecated `require('lspconfig')` startup warning and no Lua error. The three commands remain enabled even if their external executables have not been installed yet.

### Task 4: Document installation and controls

**Files:**
- Modify: `README.md` in the existing `## Neovim` section
- Test: Markdown diff/whitespace inspection

**Interfaces:**
- Consumes: the mise pins and Neovim mappings from Tasks 1–3.
- Produces: user-facing instructions for installing the tools and using completion/LSP features.

- [x] **Step 1: Extend the Neovim documentation**

Add text explaining that `./init.sh` installs the mise-managed `pyright`, `rust-analyzer`, and `marksman` tools, and that `blink.cmp` provides LSP, snippet, buffer, and path completion. Document these controls: `<C-y>` accept, `<C-space>` open, `<C-n>` / `<C-p>` navigate, `<Tab>` / `<S-Tab>` snippet navigation, `gd`, `K`, `<leader>rn`, and `<leader>ca`.

- [x] **Step 2: Check documentation formatting and intended diff**

Run:

```bash
rtk git diff --check -- README.md
rtk git diff -- README.md
```

Expected: no whitespace errors and only the new Neovim setup information appears.

### Task 5: Install external tools and perform full verification

**Files:**
- Verify: `.config/mise/global-config.toml`, `.config/nvim/init.lua`, and `README.md`
- Test: mise installation, headless Neovim startup, and final diff checks

**Interfaces:**
- Consumes: all configuration changes from Tasks 1–4.
- Produces: installed executables and evidence that the complete configuration starts and exposes the requested features.

- [x] **Step 1: Install the newly pinned mise tools**

Run the repository-linked mise installation:

```bash
rtk mise install --cd /home/iida
```

Expected: mise installs the three requested tools and exits 0. If the sandbox rejects writes to the mise installation/cache directories, rerun this exact installation with the required approval rather than changing the installation method.

- [x] **Step 2: Confirm all language-server executables**

Run:

```bash
rtk mise which pyright
rtk mise which rust-analyzer
rtk mise which marksman
```

Expected: each command returns a path under mise-managed installations, not the pre-existing manually installed `/home/iida/.local/bin` copies.

- [x] **Step 3: Start the final configuration in a fresh temporary environment**

Use a new temporary XDG directory set and run:

```bash
rtk env XDG_CONFIG_HOME=/tmp/codex-nvim-lsp-final-config XDG_DATA_HOME=/tmp/codex-nvim-lsp-final-data XDG_STATE_HOME=/tmp/codex-nvim-lsp-final-state XDG_CACHE_HOME=/tmp/codex-nvim-lsp-final-cache /home/iida/.local/share/mise/installs/neovim/0.12.4/bin/nvim --headless /tmp/codex-nvim-lsp-final-sample.py "+lua assert(type(require('blink.cmp')) == 'table')" "+lua assert(vim.fn.exists(':BlinkCmp') == 2)" "+lua assert(vim.lsp.config['pyright'])" "+lua assert(vim.lsp.config['rust_analyzer'])" "+lua assert(vim.lsp.config['marksman'])" "+lua assert(vim.lsp.is_enabled('pyright'))" "+lua assert(vim.lsp.is_enabled('rust_analyzer'))" "+lua assert(vim.lsp.is_enabled('marksman'))" "+lua assert(vim.g.mapleader == ' ')" "+lua assert(vim.opt.number:get())" +qa
```

Expected: exit code 0, with the requested completion plugin and all three LSP definitions loaded.

- [x] **Step 4: Review the complete change and preserve unrelated work**

Run:

```bash
rtk git diff --check
rtk git status --short
rtk git diff -- .config/mise/global-config.toml .config/nvim/init.lua README.md
```

Expected: no whitespace errors; only the three requested configuration/documentation files are modified; no implementation commit is created unless the user separately asks for one.
