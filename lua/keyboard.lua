-- ─────────────────────────────────────────────────────────────────────────────
--  Раскладка клавиатуры: русская + английская
-- ─────────────────────────────────────────────────────────────────────────────
--
--  Neovim видит только ту клавишу, которая реально нажата. Если раскладка
--  переключена на русскую, то `<Leader>tt` превращается в `<Leader>ее` и
--  маппинг «не работает». Здесь это лечится двумя механизмами:
--
--  1. twins (основной, работает всегда) — мы перехватываем определение
--     маппингов (`vim.keymap.set`, `vim.api.nvim_set_keymap`,
--     `vim.api.nvim_buf_set_keymap`) и автоматически регистрируем такой же
--     маппинг на кириллической клавише в той же физической позиции.
--     Это покрывает ВСЕ маппинги, которые определяются после `patch()`:
--     init.lua, стандартные маппинги AstroNvim, плагины (neo-tree,
--     better-escape, crates.nvim, …).
--
--  2. langmap (дополнительный) — встроенные команды Normal/Visual режима
--     (`dd`, `yy`, `ciw`, `gg`, …) понимают кириллицу. Переключается
--     в рантайме через `<Leader>uK` / `:KeyboardLayout`.
--
--  Прозрачность окна настраивается в `lua/polish.lua`, это другой файл.
--
--  Настройка (флаги ниже):
--    enabled = false  — полностью выключить поддержку раскладок
--    twins   = false  — не дублировать маппинги кириллицей
--    langmap = false  — не включать кириллицу для встроенных команд
-- ─────────────────────────────────────────────────────────────────────────────

local M = {}

M.opts = {
  enabled = true,
  twins = true,
  langmap = true,
  -- Одиночные клавиши в режиме вставки/командной строки (это обычный текст):
  --   "expr" — только expr-маппинги, так устроены «jk»-последовательности
  --            (better-escape), обычный русский текст не затрагивается;
  --   "all"  — все (может мешать вводу текста, использовать осознанно);
  --   "none" — никакие.
  insert_twins = "expr",
  -- Встроенные команды Normal/Visual, которые в русской раскладке дают другой
  -- символ: `:` на клавише `;`, `.` на клавише `/`, `<`/`>` на `,`/`.`
  builtin_twins = true,
}

--- Встроенные команды, которые раскладка «ломает» (знаки препинания).
---@type { modes: string[], lhs: string, rhs: string, desc: string }[]
local BUILTIN_TWINS = {
  { modes = { "n" }, lhs = "Ж", rhs = ":", desc = "Командная строка (Ex)" },
  {
    modes = { "x", "v" },
    lhs = "Ж",
    rhs = ":",
    desc = "Командная строка для выделения (Ex)",
  },
  { modes = { "n" }, lhs = "ю", rhs = ".", desc = "Повторить последнее изменение" },
  { modes = { "x", "v" }, lhs = "Б", rhs = "<", desc = "Сдвинуть влево" },
  { modes = { "x", "v" }, lhs = "Ю", rhs = ">", desc = "Сдвинуть вправо" },
}

-- Пары «латинская клавиша → русская клавиша» для одной и той же физической
-- клавиши (раскладка ЙЦУКЕН, как в Windows/Linux).
-- ВАЖНО: порядок символов в строках должен совпадать.
local LAYOUT = {
  {
    en = "qwertyuiop[]asdfghjkl;'zxcvbnm,./`",
    ru = "йцукенгшщзхъфывапролджэячсмитьбю.ё",
  },
  {
    en = 'QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>?~',
    ru = "ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,Ё",
  },
}

--- Таблица перевода одиночных символов: `["q"] = "й"` и т.д.
---@type table<string, string>
local char_map = {}

do
  for _, row in ipairs(LAYOUT) do
    local en, ru = vim.fn.str2list(row.en), vim.fn.str2list(row.ru)
    for i = 1, math.min(#en, #ru) do
      char_map[vim.fn.nr2char(en[i])] = vim.fn.nr2char(ru[i])
    end
  end
end

--- Переводит все символы строки в «соседнюю» раскладку (посимвольно).
---@param str string
---@return string
local function translate_chars(str)
  local out = {}
  for _, codepoint in ipairs(vim.fn.str2list(str)) do
    local char = vim.fn.nr2char(codepoint)
    out[#out + 1] = char_map[char] or char
  end
  return table.concat(out)
end

---@param lhs string
---@return boolean
local function is_single_char(lhs) return #vim.fn.str2list(lhs) == 1 end

--- Режимы, в которых одиночная клавиша — это текст, а не команда.
---@param mode string|string[]
---@return boolean
local function is_text_input_mode(mode)
  local modes = type(mode) == "table" and mode or { mode }
  for _, value in ipairs(modes) do
    if type(value) == "string" then
      if value == "!" then return true end
      if value:find("i", 1, true) or value:find("c", 1, true) or value:find("t", 1, true) then return true end
    end
  end
  return false
end

--- Значение leader-клавиши, вставленное в строку как обычные символы.
--- Специальные клавиши (`<C-Space>` и подобные) трогать бессмысленно — они
--- одинаковы в любой раскладке, поэтому оставляем их токеном.
local function leader_literal(value)
  if type(value) ~= "string" or value == "" then return nil end
  if value:find("<", 1, true) then return nil end
  return value
end

--- Маскирует `<...>`-токены, чтобы не переводить их содержимое,
--- и раскрывает `<Leader>`/`<LocalLeader>` в реальные клавиши.
---@param lhs string
---@return string masked, fun(str: string): string restore
local function mask_lhs(lhs)
  local specials = {}
  local function stash(value)
    specials[#specials + 1] = value
    return "\1" .. #specials .. "\1"
  end

  local leader = leader_literal(vim.g.mapleader)
  local localleader = leader_literal(vim.g.maplocalleader)

  local masked = lhs
  -- <Leader> / <LocalLeader> -> реальные клавиши (пробел, запятая, …).
  -- Подставляем как обычные символы, чтобы запятая тоже перевелась в «б».
  masked = masked:gsub("<LocalLeader>", function() return localleader or stash "<LocalLeader>" end)
  masked = masked:gsub("<Leader>", function() return leader or stash "<Leader>" end)
  -- клавиши, записанные токенами, но означающие обычный символ
  masked = masked:gsub("<lt>", function() return stash "<" end)
  masked = masked:gsub("<gt>", function() return stash ">" end)
  masked = masked:gsub("<Bslash>", function() return stash "\\" end)
  masked = masked:gsub("<Bar>", function() return stash "|" end)
  -- все остальные специальные клавиши (<Esc>, <C-w>, <A-Left>, <Plug>, …)
  masked = masked:gsub("<[^<>]+>", function(token) return stash(token) end)

  local function restore(str)
    return (str:gsub("\1(%d+)\1", function(index) return specials[tonumber(index)] end))
  end

  return masked, restore
end

--- Возвращает кириллические «двойники» для маппинга (обычно один).
---@param mode string|string[]
---@param lhs string
---@param opts table|nil опции маппинга (`expr`, `buffer`, …)
---@param ignore_policy boolean|nil вернуть двойников независимо от политики
---@return string[]
function M.twins(mode, lhs, opts, ignore_policy)
  if not (M.opts.enabled and M.opts.twins) then return {} end
  if type(lhs) ~= "string" or lhs == "" then return {} end
  -- внутренние маппинги (<Plug>, <SID>, <SNR>) набирать руками невозможно
  if lhs:find("<Plug>", 1, true) or lhs:find("<SID>", 1, true) or lhs:find("<SNR>", 1, true) then return {} end
  -- одиночную букву в режиме вставки/командной строки дублируем только
  -- для expr-маппингов, иначе русская буква перестанет вставляться как текст
  if is_text_input_mode(mode) and is_single_char(lhs) and not ignore_policy then
    local policy = M.opts.insert_twins
    if policy == "none" then return {} end
    if policy ~= "all" and not (type(opts) == "table" and opts.expr == true) then return {} end
  end

  local masked, restore = mask_lhs(lhs)
  local canonical = restore(masked) -- как маппинг выглядит на самом деле
  local twin = restore(translate_chars(masked)) -- то же, но в русской раскладке

  if twin == "" or twin == canonical or twin == lhs then return {} end
  return { twin }
end

--- Регистрирует двойники для всех lhs маппинга (lhs может быть таблицей).
---@param set fun(mode: string|string[], lhs: string, rhs: any, opts?: table): any
---@param mode string|string[]
---@param lhs string|string[]
---@param rhs any
---@param opts table|nil
function M.register_twins(set, mode, lhs, rhs, opts)
  local list = type(lhs) == "table" and lhs or { lhs }
  for _, value in ipairs(list) do
    for _, twin in ipairs(M.twins(mode, value, opts)) do
      local twin_opts = opts and vim.tbl_extend("force", {}, opts) or nil
      pcall(set, mode, twin, rhs, twin_opts) -- двойник не должен ломать загрузку
    end
  end
end

--- Удаляет двойников маппинга (вместе с оригиналом, чтобы не оставалось
--- «висячих» обработчиков).
---@param del fun(mode: string|string[], lhs: string): any
---@param mode string|string[]
---@param lhs string|string[]
function M.delete_twins(del, mode, lhs)
  local list = type(lhs) == "table" and lhs or { lhs }
  for _, value in ipairs(list) do
    for _, twin in ipairs(M.twins(mode, value, nil, true)) do
      pcall(del, mode, twin)
    end
  end
end

--- Перехватывает определение маппингов. Вызывать ОДИН раз, до `lazy_setup`,
--- иначе стандартные маппинги AstroNvim и плагинов останутся без двойников.
function M.patch()
  if M._patched then return end
  M._patched = true

  local keymap_set = vim.keymap.set
  local keymap_del = vim.keymap.del
  local set_keymap = vim.api.nvim_set_keymap
  local buf_set_keymap = vim.api.nvim_buf_set_keymap
  local del_keymap = vim.api.nvim_del_keymap
  local buf_del_keymap = vim.api.nvim_buf_del_keymap

  vim.keymap.set = function(mode, lhs, rhs, opts)
    local result = keymap_set(mode, lhs, rhs, opts)
    M.register_twins(keymap_set, mode, lhs, rhs, opts)
    return result
  end

  vim.keymap.del = function(mode, lhs, opts)
    M.delete_twins(function(m, l) return keymap_del(m, l, opts) end, mode, lhs)
    return keymap_del(mode, lhs, opts)
  end

  vim.api.nvim_set_keymap = function(mode, lhs, rhs, opts)
    local result = set_keymap(mode, lhs, rhs, opts)
    M.register_twins(set_keymap, mode, lhs, rhs, opts)
    return result
  end

  vim.api.nvim_buf_set_keymap = function(buffer, mode, lhs, rhs, opts)
    local result = buf_set_keymap(buffer, mode, lhs, rhs, opts)
    -- opts у nvim_buf_set_keymap не содержит buffer, поэтому передаём его
    -- через замыкание, чтобы двойник попал в тот же буфер
    M.register_twins(function(m, l, r, o) return buf_set_keymap(buffer, m, l, r, o) end, mode, lhs, rhs, opts)
    return result
  end

  -- Удаление: двойники не должны переживать оригинал, иначе останутся
  -- «висячие» обработчики (так neo-tree/nui обновляют свои маппинги).
  vim.api.nvim_del_keymap = function(mode, lhs)
    M.delete_twins(function(m, l) return del_keymap(m, l) end, mode, lhs)
    return del_keymap(mode, lhs)
  end

  vim.api.nvim_buf_del_keymap = function(buffer, mode, lhs)
    M.delete_twins(function(m, l) return buf_del_keymap(buffer, m, l) end, mode, lhs)
    return buf_del_keymap(buffer, mode, lhs)
  end
end

--- Значение опции `langmap` для кириллицы (только буквы — так надёжнее:
--- запятая и обратный слэш в этой опции служебные).
---@return string
local function langmap_value()
  local parts = {}
  for _, row in ipairs(LAYOUT) do
    local from, to = {}, {}
    local en, ru = vim.fn.str2list(row.en), vim.fn.str2list(row.ru)
    for i = 1, math.min(#en, #ru) do
      local latin, cyrillic = vim.fn.nr2char(en[i]), vim.fn.nr2char(ru[i])
      if latin:match "^[A-Za-z]$" then
        from[#from + 1] = cyrillic
        to[#to + 1] = latin
      end
    end
    parts[#parts + 1] = table.concat(from) .. ";" .. table.concat(to)
  end
  return table.concat(parts, ",")
end

--- Включает/выключает `langmap` (встроенные команды на кириллице).
function M.apply_langmap()
  if not (M.opts.enabled and M.opts.langmap) then
    vim.opt.langmap = ""
    return
  end
  vim.opt.langmap = langmap_value()
  vim.opt.langremap = false -- не переводить символы, полученные из маппингов
end

---@return string
function M.status()
  local langmap_state = (M.opts.enabled and M.opts.langmap) and "включён" or "выключен"
  local twins_state = (M.opts.enabled and M.opts.twins) and "включены" or "выключены"
  return ("Раскладка: команды на кириллице (langmap) — %s, двойники маппингов — %s"):format(
    langmap_state,
    twins_state
  )
end

function M.toggle_langmap()
  M.opts.langmap = not M.opts.langmap
  M.apply_langmap()
  vim.notify(
    M.opts.langmap and "Кириллица в Normal/Visual режиме включена (dd, ciw, gg, …)"
      or "Кириллица в Normal/Visual режиме выключена",
    vim.log.levels.INFO
  )
end

--- Вызывать ПОСЛЕ `require "lazy_setup"`: нужен уже заданный mapleader.
function M.setup()
  M.apply_langmap()

  if M.opts.enabled and M.opts.builtin_twins then
    for _, mapping in ipairs(BUILTIN_TWINS) do
      for _, mode in ipairs(mapping.modes) do
        vim.keymap.set(mode, mapping.lhs, mapping.rhs, { desc = mapping.desc })
      end
    end
  end

  vim.keymap.set("n", "<Leader>uK", M.toggle_langmap, { desc = "⌨️ Кириллица в Normal/Visual (langmap)" })

  vim.api.nvim_create_user_command("KeyboardLayout", function(ctx)
    if ctx.args == "toggle" then
      M.toggle_langmap()
    else
      vim.notify(M.status(), vim.log.levels.INFO)
    end
  end, {
    desc = "Раскладка клавиатуры: статус, `:KeyboardLayout toggle` — переключить langmap",
    nargs = "?",
    complete = function() return { "status", "toggle" } end,
  })
end

return M
