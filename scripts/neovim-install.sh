#!/bin/bash
set -e

echo "⚠️  This script will overwrite your ~/.config/nvim/init.lua and related directories."
read -p "Are you sure you want to continue? [y/N] " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "❌ Cancelled."
    exit 1
fi

echo "🔧 Checking for Neovim and dependencies..."
MISSING_PACKAGES=()
for pkg in neovim git curl build-essential; do
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
  "folke/tokyonight.nvim",
  "EdenEast/nightfox.nvim",
  "Mofiqul/vscode.nvim",
  "morhetz/gruvbox",
  -- Autocompletion
  "hrsh7th/nvim-cmp",
  "hrsh7th/cmp-buffer",
  "hrsh7th/cmp-path",
  "hrsh7th/cmp-nvim-lsp",
  "L3MON4D3/LuaSnip",
  "saadparwaiz1/cmp_luasnip",
})

-- === Default colorscheme ===
vim.cmd.colorscheme("gruvbox")
-- Change with the :Themes command

-- === Always start in insert mode ===
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.cmd("startinsert")
  end
})

-- === Make Backspace work as expected ===
vim.o.backspace = "indent,eol,start"

-- ========== KEYBINDINGS WITH EXPLANATIONS ==========

-- Ctrl+S (normal) — save file
vim.keymap.set("n", "<C-s>", ":w<CR>")
-- Ctrl+S (insert) — temporarily switch to normal, save, return to insert
vim.keymap.set("i", "<C-s>", "<Esc>:w<CR>gi")

-- Ctrl+Y (normal) — delete current line (VSCode-style)
vim.keymap.set("n", "<C-y>", "dd")
-- Ctrl+Y (insert) — temporarily switch to normal, delete line, return to insert
vim.keymap.set("i", "<C-y>", "<Esc>ddi")

-- Esc (insert) — does nothing (single Esc disabled to avoid accidental mode switches)
vim.keymap.set("i", "<Esc>", "<Nop>")
-- Double Esc (any mode) — prompt to save before exiting
vim.keymap.set("i", "<Esc><Esc>", "<Esc>:confirm q<CR>")
vim.keymap.set("n", "<Esc><Esc>", ":confirm q<CR>")

-- F10 (any mode) — prompt to save before exiting
vim.keymap.set("i", "<F10>", "<Esc>:confirm q<CR>")
vim.keymap.set("n", "<F10>", ":confirm q<CR>")


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

-- ========== AUTOCOMPLETION ==========
local cmp = require'cmp'
local luasnip = require'luasnip'
cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = {
    ['<C-Space>'] = cmp.mapping.complete(),           -- manually trigger completion menu
    ['<CR>'] = cmp.mapping.confirm({ select = true }),-- Enter — accept current suggestion
    ['<Tab>'] = cmp.mapping.select_next_item(),       -- Tab — next completion item
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),     -- Shift+Tab — previous completion item
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'buffer' },
    { name = 'path' },
    { name = 'luasnip' },
  }
})

-- ========== EXTRAS ==========

EOF

echo "✅ Done! Start nvim and wait for plugins to install automatically."
echo "🌈 You can change the colorscheme with the :Themes command."
echo "🖱️  Mouse is enabled: you can select, copy, and click."
