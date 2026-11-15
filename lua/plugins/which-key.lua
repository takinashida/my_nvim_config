-- which-key: скрываем кириллические двойники маппингов, чтобы меню не
-- дублировало каждую комбинацию (см. `lua/keyboard.lua`).
-- Двойники продолжают работать, просто не занимают место в подсказке.

---@type LazySpec
return {
  "folke/which-key.nvim",
  opts = function(_, opts)
    local previous = opts.filter
    opts.filter = function(mapping)
      if type(previous) == "function" and not previous(mapping) then return false end
      -- кириллица в UTF-8 начинается с байтов 0xD0/0xD1
      return not (mapping.lhs or ""):find "[\208\209]"
    end
  end,
}
