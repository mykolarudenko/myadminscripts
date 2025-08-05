#!/bin/bash
# Copyright (c) 2024 Mykola Rudenko
# This script is licensed under the MIT License.
# See the LICENSE file for details.
# https://github.com/mykolarudenko/myadminscripts
set -e

echo "⚠️  This script will overwrite your ~/.config/nvim/init.lua and related directories."
read -p "Are you sure you want to continue? [y/N] " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "❌ Cancelled."
    exit 1
fi

echo "🔧 Checking for Neovim and dependencies..."
MISSING_PACKAGES=()
for pkg in neovim git curl build-essential xclip ripgrep; do
    if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    echo "🔧 The following packages are missing and will be installed: ${MISSING_PACKAGES[*]}"
    sudo apt update
    sudo apt install -y "${MISSING_PACKAGES[@]}"
else
    echo "✅ Neovim and all dependencies are already installed."
fi

echo "📂 Preparing config directories..."
rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.cache/nvim
rm -rf ~/.cache/tree-sitter
mkdir -p ~/.config/nvim/lua

echo "📦 Installing lazy.nvim..."
git clone https://github.com/folke/lazy.nvim \
    ~/.local/share/nvim/site/pack/lazy/start/lazy.nvim

echo "⚙️  Writing init.lua config..."
cat > ~/.config/nvim/init.lua <<'EOF'
-- ===========================
--   Neovim config VSCode-style
-- ===========================

vim.opt.termguicolors = true

-- === Plugins with lazy.nvim ===
require("lazy").setup({
  -- Bottom statusline
  { "nvim-lualine/lualine.nvim", dependencies = { "nvim-tree/nvim-web-devicons" } },
  -- Syntax highlighting, Treesitter
  { "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdateSync",
    config = function()
      require'nvim-treesitter.configs'.setup {
        highlight = { enable = true },
        ensure_installed = { "lua", "python", "bash", "html", "css", "javascript", "json", "yaml", "markdown", "c", "cpp" },
      }
    end
  },
  -- Color schemes
  "catppuccin/nvim",
  "numToStr/Comment.nvim", -- For commenting (Ctrl+/)
  "folke/tokyonight.nvim",
  "EdenEast/nightfox.nvim",
  "Mofiqul/vscode.nvim",
  "morhetz/gruvbox",

  -- UI and helpers
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} }, -- Indentation guides
  { "folke/which-key.nvim", event = "VeryLazy", opts = {} }, -- Keybinding popup
  { 'nvim-telescope/telescope.nvim', tag = '0.1.x', -- Fuzzy finder
    dependencies = { 'nvim-lua/plenary.nvim' }
  },
})

-- === Default colorscheme ===
vim.cmd.colorscheme("vscode")
-- Change with the :Themes command

-- === Always start in insert mode ===
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.cmd("startinsert")
  end
})

-- === Make Backspace work as expected ===
vim.o.backspace = "indent,eol,start"
-- Keep indentation on new lines and when pasting
vim.o.autoindent = true

-- === Use system clipboard for yank/paste ===
vim.o.clipboard = "unnamedplus"

-- ========== KEYBINDINGS WITH EXPLANATIONS ==========

-- Ctrl+S (normal) — save file
vim.keymap.set("n", "<C-s>", ":w<CR>")
-- Ctrl+S (insert) — temporarily switch to normal, save, return to insert
vim.keymap.set("i", "<C-s>", "<Esc>:w<CR>gi")

-- F2 (any mode) — save file
vim.keymap.set("n", "<F2>", ":w<CR>")
vim.keymap.set("i", "<F2>", "<Esc>:w<CR>gi")

-- F7 (any mode) — search
vim.keymap.set("n", "<F7>", "/")
vim.keymap.set("i", "<F7>", "<Esc>/")

-- F8 (any mode) — next search result
vim.keymap.set("n", "<F8>", "n")
vim.keymap.set("i", "<F8>", "<Esc>n")

-- Shift+F8 (any mode) — previous search result
vim.keymap.set("n", "<S-F8>", "N")
vim.keymap.set("i", "<S-F8>", "<Esc>N")

-- Ctrl+Y (normal) — delete current line (VSCode-style)
vim.keymap.set("n", "<C-y>", "dd")
-- Ctrl+Y (insert) — temporarily switch to normal, delete line, return to insert
vim.keymap.set("i", "<C-y>", "<Esc>ddi")

-- Ctrl+Z (normal/insert) — undo
vim.keymap.set("n", "<C-z>", "u")
vim.keymap.set("i", "<C-z>", "<C-o>u")

-- Ctrl+C (visual) — copy selection to system clipboard
vim.keymap.set("v", "<C-c>", '"+y<Esc>')

-- Esc (insert) — does nothing (single Esc disabled to avoid accidental mode switches)
vim.keymap.set("i", "<Esc>", "<Nop>")
-- Double Esc (any mode) — prompt to save before exiting
vim.keymap.set("i", "<Esc><Esc>", "<Esc>:confirm q<CR>")
vim.keymap.set("n", "<Esc><Esc>", ":confirm q<CR>")

-- F10 (any mode) — prompt to save before exiting
vim.keymap.set("i", "<F10>", "<Esc>:confirm q<CR>")
vim.keymap.set("n", "<F10>", ":confirm q<CR>")

-- Shift+Arrows to select text (VSCode-like)
vim.keymap.set("i", "<S-Left>", "<Esc>v<Left>")
vim.keymap.set("i", "<S-Right>", "<Esc>v<Right>")
vim.keymap.set("i", "<S-Up>", "<Esc>v<Up>")
vim.keymap.set("i", "<S-Down>", "<Esc>v<Down>")
vim.keymap.set("v", "<S-Left>", "<Left>")
vim.keymap.set("v", "<S-Right>", "<Right>")
vim.keymap.set("v", "<S-Up>", "<Up>")
vim.keymap.set("v", "<S-Down>", "<Down>")

-- PageUp/PageDown for smoother half-page scrolling (VSCode-like)
vim.keymap.set("n", "<PageUp>", "<C-u>")
vim.keymap.set("n", "<PageDown>", "<C-d>")
vim.keymap.set("i", "<PageUp>", "<C-o><C-u>")
vim.keymap.set("i", "<PageDown>", "<C-o><C-d>")


-- ========== TELESCOPE (FUZZY FINDER) ==========
-- See: https://github.com/nvim-telescope/telescope.nvim
local builtin = require('telescope.builtin')
-- Ctrl+P to find files
vim.keymap.set('n', '<C-p>', builtin.find_files, { desc = "Telescope: Find files" })
-- Ctrl+G to search for a string in the project
vim.keymap.set('n', '<C-g>', builtin.live_grep, { desc = "Telescope: Live grep" })
-- Ctrl+B to search in open buffers
vim.keymap.set('n', '<C-b>', builtin.buffers, { desc = "Telescope: Find in buffers" })


-- ========== THEME SWITCHER ==========
-- Define available themes
local themes = {
  'catppuccin-latte', 'catppuccin-frappe', 'catppuccin-macchiato', 'catppuccin-mocha',
  'tokyonight', 'nightfox', 'vscode', 'gruvbox'
}
-- Create the :Themes command for interactive selection
vim.api.nvim_create_user_command('Themes', function()
  vim.ui.select(themes, { prompt = 'Select a colorscheme:' }, function(choice)
    if choice then
      vim.cmd.colorscheme(choice)
    end
  end)
end, { desc = "Select a colorscheme from a list" })


-- ========== STATUS LINE ==========
require('lualine').setup {
  options = {
    theme = 'auto',
    section_separators = '',
    component_separators = ''
  }
}

-- ========== COMMENTING (Ctrl+Shift+/ or Ctrl+Shift+#) ==========
require('Comment').setup()
-- Map <C-?> (which is Ctrl+Shift+/ on many keyboards) to toggle comments
vim.keymap.set("n", "<C-?>", "<Plug>(comment_toggle_linewise_current)")
vim.keymap.set("v", "<C-?>", "<Plug>(comment_toggle_linewise_visual)")
-- Map <C-S-3> (Ctrl+Shift+# on many keyboards) as an alternative for SSH
vim.keymap.set("n", "<C-S-3>", "<Plug>(comment_toggle_linewise_current)")
vim.keymap.set("v", "<C-S-3>", "<Plug>(comment_toggle_linewise_visual)")

-- ========== EXTRAS ==========

EOF

echo "📦 Installing plugins and parsers... (this may take a minute)"
nvim --headless "+Lazy! sync" +qa

echo "✅ Done! You can now start nvim."
echo "🌈 You can change the colorscheme with the :Themes command."
echo "🖱️  Mouse is enabled: you can select, copy, and click."
