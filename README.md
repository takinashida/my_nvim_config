# AstroNvim Template

**NOTE:** This is for AstroNvim v6+

A template for getting started with [AstroNvim](https://github.com/AstroNvim/AstroNvim)

## 🛠️ Installation

#### Make a backup of your current nvim and shared folder

```shell
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak
mv ~/.local/state/nvim ~/.local/state/nvim.bak
mv ~/.cache/nvim ~/.cache/nvim.bak
```

#### Create a new user repository from this template

Press the "Use this template" button above to create a new repository to store your user configuration.

You can also just clone this repository directly if you do not want to track your user configuration in GitHub.

#### Clone the repository

```shell
git clone https://github.com/<your_user>/<your_repository> ~/.config/nvim
```

#### Start Neovim

```shell
nvim
```

## ⌨️ Русская и английская раскладка

Все маппинги работают в обеих раскладках — реализовано в `lua/keyboard.lua`.

- `patch()` в `init.lua` перехватывает `vim.keymap.set`,
  `vim.api.nvim_set_keymap` и `vim.api.nvim_buf_set_keymap`, поэтому
  кириллические двойники получают **все** маппинги: свои, стандартные
  AstroNvim и плагинов (neo-tree, better-escape `jk` → `ол`, crates.nvim, …).
- `langmap` включает кириллицу для встроенных команд Normal/Visual
  (`dd`, `yy`, `ciw`, `gg`, `f`/`t` и т.д.).
- Знаки препинания: `:` → `Ж`, `.` (повтор) → `ю`, `<`/`>` (отступы) → `Б`/`Ю`.

Управление:

- `<Leader>uK` или `:KeyboardLayout toggle` — вкл/выкл `langmap`;
- `:KeyboardLayout` — показать статус.

Настройки — таблица `M.opts` в начале `lua/keyboard.lua`
(`enabled`, `twins`, `langmap`, `builtin_twins`, `insert_twins`).
Если у вас нестандартная раскладка (например, фонетическая), поправьте
таблицу `LAYOUT` там же.
