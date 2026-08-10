# Neovim LSP and Completion Design

## Goal

Add a reproducible development environment for Python, Rust, and Markdown to the existing Neovim configuration. The environment must provide language-server diagnostics and navigation, code completion, snippets, and filesystem path completion.

## Context

The repository keeps Neovim configuration in a single file at `.config/nvim/init.lua`, bootstraps lazy.nvim, and pins Neovim 0.12.4 and the main command-line tools with mise. The current configuration already includes Treesitter, Snacks, markview, and nvim-tree, but it has no LSP client setup or completion plugin. The current mise environment has Rust tooling and manually available Markdown servers, while Python's `pyright` is not installed.

The repository's mise configuration uses exact version pins and a seven-day minimum release age. New language servers must follow that reproducibility policy instead of being installed by Mason or an editor-specific installer.

## Design

Use three layers:

1. mise installs and exposes the external language-server executables:
   - `npm:pyright = "1.1.411"`
   - `rust-analyzer = "2026-08-03"`
   - `marksman = "2026-02-08"`
2. lazy.nvim installs `saghen/blink.cmp` from its stable v1 release line and `neovim/nvim-lspconfig` for server-specific configuration data. `rafamadriz/friendly-snippets` supplies reusable snippets.
3. Neovim 0.12's standard `vim.lsp.config` and `vim.lsp.enable` APIs configure and enable `pyright`, `rust_analyzer`, and `marksman`. Do not use the deprecated `require("lspconfig").<server>.setup()` framework.

The completion source list is explicitly set to `lsp`, `path`, `snippets`, and `buffer`. LSP capabilities are merged through blink.cmp so servers can provide completion items and snippet edits. The path source is enabled for ordinary insert-mode completion, so relative and home-directory paths are available without a separate path plugin.

The LSP plugin loads on `BufReadPre` and `BufNewFile` and depends on blink.cmp. Its configuration applies shared blink capabilities and buffer-local LSP keymaps, then enables the three servers. Each server uses nvim-lspconfig's built-in root markers and filetypes; no project-specific Python, Rust, or Markdown settings are introduced.

## User-facing behavior

blink.cmp's default keymap is used:

- `<C-y>` accepts the selected completion.
- `<C-n>` / `<C-p>` move through candidates.
- `<C-space>` opens the completion menu.
- `<Tab>` / `<S-Tab>` move through snippet placeholders when a snippet is active.

When an LSP is attached, these buffer-local mappings are added:

- `gd`: go to definition
- `K`: show hover documentation
- `<leader>rn`: rename symbol
- `<leader>ca`: code action

Diagnostic display remains visible through Neovim's diagnostic UI, with updates deferred while typing and severity sorting enabled. Existing mappings and editor options remain unchanged.

## Files and responsibilities

- `.config/mise/global-config.toml`: exact language-server version pins.
- `.config/nvim/init.lua`: lazy.nvim plugin specifications, blink.cmp setup, LSP configuration, diagnostics, and LSP keymaps.
- `README.md`: setup instructions and a concise summary of the new completion/LSP behavior.

No separate Mason configuration, formatter, linter, debugger, or language-specific project configuration is part of this change.

## Error handling

If a language-server executable is missing from PATH, Neovim's LSP health information must report it as unavailable; the configuration must still start without crashing. If a server cannot determine a workspace root, it must not attach until an appropriate root marker is found. Users can diagnose installation and attachment with `:checkhealth vim.lsp` and `:LspInfo`.

The verification environment must use temporary XDG data, state, cache, and config directories so lazy.nvim, plugin downloads, undo data, and diagnostic state do not modify the user's normal Neovim data.

## Verification

- Confirm the mise file remains valid and all three exact pins are present.
- Install or resolve the configured mise tools and confirm `pyright`, `rust-analyzer`, and `marksman` are executable.
- Start the copied Neovim configuration headlessly with temporary XDG directories.
- Confirm lazy.nvim recognizes blink.cmp, friendly-snippets, nvim-lspconfig, and the existing plugins.
- Confirm blink.cmp loads with `lsp`, `path`, `snippets`, and `buffer` sources.
- Confirm the three LSP configurations are enabled without startup errors and that existing leader mappings/options remain intact.
- Run `git diff --check` and inspect the final diff for unrelated changes.

## Scope

This change adds LSP and completion infrastructure for Python, Rust, and Markdown only. It does not add format-on-save, lint-on-save, debugging, AI completion, project-local configuration, or automatic parser installation.
