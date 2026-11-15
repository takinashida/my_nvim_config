-- Rust toolchain: rust-analyzer via rustaceanvim, crates.nvim, debugging with codelldb/DAP
-- Documentation: `:h rustaceanvim`, `:h crates`

---@type LazySpec
return {
  ---------------------------------------------------------------
  -- rustaceanvim: supercharged rust-analyzer integration
  ---------------------------------------------------------------
  {
    "mrcjkb/rustaceanvim",
    version = "^9", -- requires Neovim >= 0.12 (we have 0.12.x)
    lazy = false, -- it implements its own lazy loading
    init = function()
      vim.g.rustaceanvim = {
        tools = {
          -- run/test/debug output goes into a toggleterm window
          executor = "toggleterm",
          -- run tests in the background and report failures as diagnostics
          test_executor = "background",
          crate_test_executor = "background",
          -- enables `clippy` instead of `cargo check` when available
          enable_clippy = true,
          reload_workspace_from_cargo_toml = true,
          -- show single (non grouped) code actions in the ui.select menu too
          code_actions = { ui_select_fallback = true },
          float_win_config = { auto_focus = false, open_split = "horizontal" },
        },
        server = {
          on_attach = function(client, bufnr)
            -- NOTE: rustaceanvim >= 9 registers the client as "rust-analyzer"
            if not vim.tbl_contains({ "rust-analyzer", "rust_analyzer" }, client.name) then return end
            -- K shows rust-analyzer hover *actions* (open docs, implement, goto type, ...)
            vim.keymap.set("n", "K", function() vim.cmd.RustLsp { "hover", "actions" } end, {
              buffer = bufnr,
              desc = "Hover actions (Rust)",
            })
          end,
          -- Settings passed to rust-analyzer (`:RustAnalyzer config` shows them)
          default_settings = {
            ["rust-analyzer"] = {
              cargo = {
                allFeatures = true,
                buildScripts = { enable = true },
              },
              -- run clippy on save and publish its warnings as diagnostics
              check = {
                command = "clippy",
                -- NOTE: do not add "--all-targets" here, rust-analyzer already
                -- passes it and cargo would reject the duplicate
              },
              checkOnSave = true,
              procMacro = { enable = true },
              completion = {
                autoimport = { enable = true },
                callable = { snippets = "fill_arguments" },
                postfix = { enable = true },
                termSearch = { enable = true },
              },
              imports = {
                granularity = { group = "module" },
                prefix = "crate",
              },
              assist = {
                importEnforceGranularity = true,
                importPrefix = "crate",
              },
              -- inline hints: types, parameter names, closing braces, ...
              inlayHints = {
                bindingModeHints = { enable = false },
                chainingHints = { enable = true },
                closingBraceHints = { enable = true, minLines = 25 },
                closureReturnTypeHints = { enable = "with_block" },
                lifetimeElisionHints = { enable = "skip_trivial", useParameterNames = true },
                parameterHints = { enable = true },
                typeHints = { enable = true, hideClosureInitialization = false, hideNamedConstructor = false },
              },
              hover = { actions = { enable = true, debug = { enable = true } } },
              -- run/debug/test lenses above functions and modules
              lens = {
                enable = true,
                run = { enable = true },
                debug = { enable = true },
                implementations = { enable = true },
                references = {
                  adt = { enable = true },
                  enumVariant = { enable = true },
                  method = { enable = true },
                  trait = { enable = true },
                },
              },
              semanticHighlighting = { operator = { specialization = { enable = true } } },
              diagnostics = { enable = true, experimental = { enable = true } },
              files = { excludeDirs = { ".git", "node_modules", "target", ".direnv" } },
              workspace = { symbol = { search = { kind = "all_symbols" } } },
            },
          },
        },
        dap = {
          -- load debug targets from rust-analyzer and `.vscode/launch.json`
          autoload_configurations = true,
        },
      }
    end,
  },

  ---------------------------------------------------------------
  -- crates.nvim: crate names/versions/features in Cargo.toml
  ---------------------------------------------------------------
  {
    "Saecki/crates.nvim",
    version = "^0.7",
    event = { "BufRead Cargo.toml", "BufNewFile Cargo.toml" },
    opts = {
      smart_insert = true,
      autoload = true,
      autoupdate = true,
      lsp = {
        enabled = true, -- in-process LSP: completion, hover, code actions
        actions = true,
        completion = true,
        hover = true,
      },
      completion = {
        crates = { enabled = true, min_chars = 2, max_results = 10 },
      },
      popup = { autofocus = false, border = "rounded", show_version_date = true },
      on_attach = function(bufnr)
        local function map(mode, lhs, rhs, desc) vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc }) end
        local function crates() return require "crates" end
        map("n", "<Leader>ru", function() crates().update_crate() end, "Update crate")
        map("v", "<Leader>ru", function() crates().update_crates() end, "Update crates")
        map("n", "<Leader>rU", function() crates().upgrade_crate() end, "Upgrade crate")
        map("v", "<Leader>rU", function() crates().upgrade_crates() end, "Upgrade crates")
        map("n", "<Leader>rA", function() crates().upgrade_all_crates() end, "Upgrade all crates")
        map("n", "<Leader>rv", function() crates().show_versions_popup() end, "Crate versions")
        map("n", "<Leader>rF", function() crates().show_features_popup() end, "Crate features")
        map("n", "<Leader>rN", function() crates().show_dependencies_popup() end, "Crate dependencies")
        map("n", "<Leader>rP", function() crates().show_crate_popup() end, "Crate information")
        map("n", "<Leader>rK", function() crates().open_documentation() end, "Open crate docs")
        map("n", "<Leader>rX", function() crates().toggle() end, "Toggle crates annotations")
        map("n", "<Leader>rL", function() crates().reload() end, "Reload crates")
      end,
    },
  },

  ---------------------------------------------------------------
  -- Keymaps for all the `:RustLsp` functionality
  ---------------------------------------------------------------
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      local function rust_lsp(cmd)
        if vim.bo.filetype ~= "rust" then
          require("astrocore").notify("This command is only available in Rust buffers", vim.log.levels.WARN)
          return
        end
        vim.cmd.RustLsp(cmd)
      end

      local maps = opts.mappings
      maps.n["<Leader>r"] = { desc = "🦀 Rust" }
      maps.v["<Leader>r"] = { desc = "🦀 Rust" }

      -- grouped code actions (clippy fixes, imports, refactors, ...)
      maps.n["<Leader>ra"] = { function() rust_lsp "codeAction" end, desc = "Code action (grouped)" }
      maps.n["<Leader>rr"] = { function() rust_lsp "runnables" end, desc = "Run (select target)" }
      maps.n["<Leader>rR"] = { function() rust_lsp "run" end, desc = "Run target at cursor" }
      maps.n["<Leader>rt"] = { function() rust_lsp "testables" end, desc = "Test (select target)" }
      maps.n["<Leader>rT"] = { function() rust_lsp { "testables", bang = true } end, desc = "Rerun last test" }
      maps.n["<Leader>rd"] = { function() rust_lsp "debuggables" end, desc = "Debug (select target)" }
      maps.n["<Leader>rD"] = { function() rust_lsp "debug" end, desc = "Debug target at cursor" }
      maps.n["<Leader>re"] = { function() rust_lsp "explainError" end, desc = "Explain error (E0xxx)" }
      maps.n["<Leader>rE"] = { function() rust_lsp "renderDiagnostic" end, desc = "Render diagnostic" }
      maps.n["<Leader>rm"] = { function() rust_lsp "expandMacro" end, desc = "Expand macro" }
      maps.n["<Leader>rM"] = { function() rust_lsp { "expandMacro", "float" } end, desc = "Expand macro (float)" }
      maps.n["<Leader>rc"] = { function() rust_lsp "openCargo" end, desc = "Open Cargo.toml" }
      maps.n["<Leader>ro"] = { function() rust_lsp "openDocs" end, desc = "Open docs.rs for symbol" }
      maps.n["<Leader>rp"] = { function() rust_lsp "parentModule" end, desc = "Go to parent module" }
      maps.n["<Leader>rj"] = { function() rust_lsp "joinLines" end, desc = "Join lines" }
      maps.n["<Leader>rs"] = { function() rust_lsp "syntaxTree" end, desc = "Syntax tree" }
      maps.n["<Leader>rh"] = { function() rust_lsp { "view", "hir" } end, desc = "View HIR" }
      maps.n["<Leader>rH"] = { function() rust_lsp { "view", "mir" } end, desc = "View MIR" }
      maps.n["<Leader>rf"] = { function() rust_lsp { "flyCheck", "run" } end, desc = "Run fly check (clippy)" }
      maps.n["<Leader>rx"] = { function() rust_lsp "rebuildProcMacros" end, desc = "Rebuild proc macros" }
      maps.n["<Leader>rl"] = { function() rust_lsp "logFile" end, desc = "Open rust-analyzer log" }
      maps.n["<Leader>rw"] = { function() rust_lsp "reloadWorkspace" end, desc = "Reload cargo workspace" }
    end,
  },
}
