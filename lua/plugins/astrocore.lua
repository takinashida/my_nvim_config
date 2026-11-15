-- AstroCore: central place to modify mappings, vim options, autocommands, etc.
-- Documentation: `:h astrocore`

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    -- Configure core features of AstroNvim
    features = {
      large_buf = { size = 1024 * 256, lines = 10000 },
      autopairs = true, -- enable autopairs at start
      cmp = true, -- enable completion at start
      diagnostics = { virtual_text = true, virtual_lines = false },
      highlighturl = true,
      notifications = true,
    },
    -- Diagnostics configuration (passed to `vim.diagnostic.config`)
    diagnostics = {
      virtual_text = { spacing = 2, prefix = "●" },
      underline = true,
      update_in_insert = false,
      severity_sort = true,
      float = { border = "rounded", source = true, header = "", prefix = "" },
      jump = { float = true },
    },
    -- Options passed to `vim.filetype.add`
    filetypes = {},
    -- vim options can be configured here
    options = {
      opt = { -- vim.opt.<key>
        relativenumber = true,
        number = true,
        spell = false,
        signcolumn = "yes",
        wrap = false,
        mouse = "a", -- enable the mouse everywhere
        clipboard = "unnamedplus", -- use the system clipboard
        scrolloff = 8, -- keep some context around the cursor
        sidescrolloff = 8,
        updatetime = 250, -- faster diagnostics/git signs
        timeoutlen = 400, -- snappier which-key/leader
        splitright = true,
        splitbelow = true,
        undofile = true, -- persistent undo history
        confirm = true,
        -- keep rust files at 4 spaces, everything else as in the defaults
        shiftwidth = 2,
        tabstop = 2,
        expandtab = true,
      },
      g = {
        -- configure global vim variables (vim.g)
        -- NOTE: `mapleader` and `maplocalleader` are set in `lua/lazy_setup.lua`
      },
    },
    -- Mappings can be configured through AstroCore as well.
    -- NOTE: keycodes follow the casing in the vimdocs (`<Leader>` must be capitalized)
    mappings = {
      n = {
        -- navigate buffer tabs
        ["]b"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
        ["[b"] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },
      },
    },
    -- Autocommands, e.g. filetype specific settings
    autocmds = {
      rust_filetype = {
        {
          event = "FileType",
          pattern = "rust",
          desc = "Use 4 spaces for Rust files",
          callback = function()
            vim.opt_local.expandtab = true
            vim.opt_local.tabstop = 4
            vim.opt_local.softtabstop = 4
            vim.opt_local.shiftwidth = 4
          end,
        },
      },
    },
  },
}
