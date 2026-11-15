-- This file simply bootstraps the installation of Lazy.nvim and then calls other files for execution
-- This file doesn't necessarily need to be touched, BE CAUTIOUS editing this file and proceed at your own risk.
local lazypath = vim.env.LAZY or vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not (vim.env.LAZY or (vim.uv or vim.loop).fs_stat(lazypath)) then
  -- stylua: ignore
  local result = vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
  if vim.v.shell_error ~= 0 then
    -- stylua: ignore
    vim.api.nvim_echo({ { ("Error cloning lazy.nvim:\n%s\n"):format(result), "ErrorMsg" }, { "Press any key to exit...", "MoreMsg" } }, true, {})
    vim.fn.getchar()
    vim.cmd.quit()
  end
end

vim.opt.rtp:prepend(lazypath)

-- validate that lazy is available
if not pcall(require, "lazy") then
  -- stylua: ignore
  vim.api.nvim_echo({ { ("Unable to load lazy from: %s\n"):format(lazypath), "ErrorMsg" }, { "Press any key to exit...", "MoreMsg" } }, true, {})
  vim.fn.getchar()
  vim.cmd.quit()
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Поддержка русской и английской раскладки клавиатуры (см. `lua/keyboard.lua`)
--
-- `patch()` обязательно ДО `require "lazy_setup"`: он перехватывает определение
-- маппингов, поэтому кириллические двойники получают и стандартные маппинги
-- AstroNvim, и все плагины. `setup()` — наоборот, после, когда уже задан leader.
-- ─────────────────────────────────────────────────────────────────────────────
local keyboard = require "keyboard"
keyboard.patch()

-- Window navigation with Alt + Arrow keys
local map = vim.keymap.set

map("n", "<A-Left>", "<C-w>h", { desc = "Go to left window" })
map("n", "<A-Down>", "<C-w>j", { desc = "Go to bottom window" })
map("n", "<A-Up>", "<C-w>k", { desc = "Go to top window" })
map("n", "<A-Right>", "<C-w>l", { desc = "Go to right window" })

vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], {
  desc = "Exit terminal mode",
})

-- Windows-like keyboard shortcuts (EN + RU)

-- Copy
vim.keymap.set({ "n", "v" }, "<C-c>", '"+y')
vim.keymap.set({ "n", "v" }, "<C-с>", '"+y') -- Русская с

-- Paste
vim.keymap.set({ "n", "v" }, "<C-v>", '"+p')
vim.keymap.set({ "n", "v" }, "<C-м>", '"+p') -- Русская м

-- Undo
vim.keymap.set("n", "<C-z>", "u")
vim.keymap.set("n", "<C-я>", "u") -- Русская я

-- Redo
vim.keymap.set("n", "<C-x>", "<C-r>")
vim.keymap.set("n", "<C-ч>", "<C-r>") -- Русская ч

-- Shift + Arrows: select text (Windows style)
vim.keymap.set("n", "<S-Left>", "v<Left>")
vim.keymap.set("n", "<S-Right>", "v<Right>")
vim.keymap.set("n", "<S-Up>", "v<Up>")
vim.keymap.set("n", "<S-Down>", "v<Down>")

-- Extend selection in Visual Mode
vim.keymap.set("v", "<S-Left>", "<Left>")
vim.keymap.set("v", "<S-Right>", "<Right>")
vim.keymap.set("v", "<S-Up>", "<Up>")
vim.keymap.set("v", "<S-Down>", "<Down>")

require "lazy_setup"
require "polish"

keyboard.setup()
