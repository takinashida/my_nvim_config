-- Customize Mason: automatically install all the tools used by this config
-- See the package names with `:Mason`

---@type LazySpec
return {
  -- use mason-tool-installer for automatically installing Mason packages
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    -- overrides `require("mason-tool-installer").setup(...)`
    opts = {
      -- Make sure to use the names found in `:Mason`
      ensure_installed = {
        -- language servers
        "lua-language-server",
        "json-lsp",
        "taplo", -- TOML (+ Cargo.toml schemas)

        -- formatters
        "stylua", -- lua
        "prettier", -- json/yaml/markdown/css/html

        -- debuggers
        "codelldb", -- Rust (used by rustaceanvim + nvim-dap)
        "debugpy", -- Python

        -- other tools
        "tree-sitter-cli",
      },
      -- NOTE: rust-analyzer itself is intentionally NOT installed through Mason.
      -- It comes with rustup (`rustup component add rust-analyzer`) so that the
      -- server version always matches your toolchain.
      auto_update = false,
      run_on_start = true,
      start_delay = 3000, -- wait a bit so startup is not blocked
      debounce_hours = 6, -- at least 6 hours between checks for missing tools
    },
  },
}
