-- Neovim starter configuration.
-- Keep this file small while learning the editor; add plugins only when you
-- know which problem they solve.

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

-- Display and navigation
opt.number = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.mouse = "a"
opt.splitbelow = true
opt.splitright = true
opt.termguicolors = true

-- Editing
opt.expandtab = true
opt.shiftwidth = 2
opt.softtabstop = 2
opt.tabstop = 2
opt.breakindent = true
opt.smartindent = true

-- Search and completion
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true
opt.completeopt = { "menuone", "noselect" }

-- Persistent undo and sensible defaults
opt.undofile = true
opt.updatetime = 250
opt.timeoutlen = 400
opt.confirm = true

local undo_dir = vim.fn.stdpath("state") .. "/undo"
vim.fn.mkdir(undo_dir, "p")
opt.undodir = undo_dir

local map = vim.keymap.set
local opts = { silent = true }

-- The space key is the leader: <leader>w means Space, then w.
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit window" })
map("n", "<leader>e", "<cmd>Explore<cr>", { desc = "File explorer" })
map("n", "<leader>h", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- Move between splits without reaching for Ctrl-w first.
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

-- Escape insert mode with a familiar double-tap.
map("i", "jj", "<Esc>")

-- Keep the cursor centered while scrolling and searching.
map("n", "<C-d>", "<C-d>zz", opts)
map("n", "<C-u>", "<C-u>zz", opts)
map("n", "n", "nzzzv", opts)
map("n", "N", "Nzzzv", opts)

-- Use the current working directory for :find and :Explore.
vim.cmd([[autocmd BufEnter * silent! lcd %:p:h]])
