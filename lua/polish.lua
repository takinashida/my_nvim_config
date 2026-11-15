-- Прозрачный фон Neovim.
--
-- Этот файл выполняется последним при загрузке, поэтому здесь можно спокойно
-- снимать фон у готовых highlight-групп (в том числе созданных плагинами).
--
-- ВАЖНО: сама прозрачность окна (и блюр/acrylic) — это настройка терминала,
-- а не Neovim. В Windows Terminal включены "opacity" и "useAcrylic".
-- Без них окно Neovim будет "прозрачным" до цвета фона терминала.

local M = {}

M.enabled = true

-- Группы, у которых фон убирается полностью
M.base = {
  "Normal",
  "NormalNC",
  "NormalFloat",
  "NormalSB",
  "EndOfBuffer",
  "SignColumn",
  "LineNr",
  "WinSeparator",
  "VertSplit",
  "WinBar",
  "WinBarNC",
  "StatusLine",
  "StatusLineNC",
  "StatusLineTerm",
  "StatusLineTermNC",
  "TabLine",
  "TabLineFill",
  "TabLineSel",
  "Pmenu",
  "PmenuSbar",
  "PmenuThumb",
  "FloatBorder",
  "FloatTitle",
  "FloatFooter",
}

-- Семейства групп плагинов (Neo-tree, Snacks, blink.cmp, which-key и т.д.)
M.prefixes = {
  "Snacks",
  "NeoTree",
  "Telescope",
  "NvimTree",
  "WhichKey",
  "Noice",
  "Notify",
  "Trouble",
  "Aerial",
  "DapUI",
  "BlinkCmp",
}

--- Убирает фон у одной highlight-группы, сохраняя цвета текста и атрибуты
---@param name string
local function clear_bg(name)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = true })
  if not ok or hl.link or not hl.bg then return end
  hl.bg = nil
  pcall(vim.api.nvim_set_hl, 0, name, hl)
end

--- Применяет прозрачность ко всем нужным группам
function M.apply()
  if not M.enabled then return end
  for _, name in ipairs(M.base) do clear_bg(name) end
  for name in pairs(vim.api.nvim_get_hl(0, {})) do
    for _, prefix in ipairs(M.prefixes) do
      if name:sub(1, #prefix) == prefix then
        clear_bg(name)
        break
      end
    end
  end
end

--- Включает/выключает прозрачный фон
function M.toggle()
  M.enabled = not M.enabled
  if M.enabled then
    M.apply()
  elseif vim.g.colors_name then
    -- вернуть исходные цвета темы
    pcall(vim.cmd.colorscheme, vim.g.colors_name)
  end
end

-- Применяем при каждой смене темы (в том числе при старте) и после полной загрузки
local group = vim.api.nvim_create_augroup("UserTransparentBackground", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
  group = group,
  callback = function() vim.schedule(M.apply) end,
})
vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  callback = function() vim.schedule(M.apply) end,
})

vim.api.nvim_create_user_command("TransparentToggle", M.toggle, { desc = "Прозрачный фон вкл/выкл" })
vim.keymap.set("n", "<Leader>uT", "<Cmd>TransparentToggle<CR>", { desc = "Прозрачный фон (вкл/выкл)" })

M.apply()

return M
