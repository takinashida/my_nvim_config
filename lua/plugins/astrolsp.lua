-- AstroLSP: language servers, diagnostics, formatting, inlay hints, codelens, etc.
-- Documentation: `:h astrolsp`

---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    -- Features enabled on attach for every language server
    features = {
      codelens = true, -- run/debug/test lenses and references above items
      inlay_hints = true, -- show type/parameter hints inline (toggle with <Leader>uH)
      semantic_tokens = true, -- richer highlighting from the LSP
    },
    -- Formatting (rustfmt via rust-analyzer, taplo for toml, stylua, ...)
    formatting = {
      format_on_save = {
        enabled = true,
        ignore_filetypes = {
          "markdown", -- no formatter for markdown by default
          "text",
          "gitcommit",
          "dap-repl",
        },
      },
      disabled = {},
      timeout_ms = 3000, -- rustfmt on a big crate can be slow
    },
    -- Servers that should be enabled even if they are not installed through Mason
    servers = {
      -- add server names here if you install a language server manually
    },
    -- Server-specific settings, merged with the nvim-lspconfig defaults
    config = {
      taplo = {
        settings = {
          taplo = {
            formatter = { alignEntries = false },
            schema = { enabled = true },
          },
        },
      },
    },
    handlers = {
      -- rust-analyzer is fully managed by rustaceanvim (see `lua/plugins/rust.lua`),
      -- otherwise two clients would try to start it
      rust_analyzer = false,
    },
    -- Buffer local mappings added when a language server attaches
    mappings = {
      n = {
        gD = {
          function() vim.lsp.buf.declaration() end,
          desc = "Declaration of current symbol",
          cond = "textDocument/declaration",
        },
        ["<Leader>uY"] = {
          function() require("astrolsp.toggles").buffer_semantic_tokens() end,
          desc = "Toggle LSP semantic highlight (buffer)",
          cond = function(client)
            return client:supports_method "textDocument/semanticTokens/full" and vim.lsp.semantic_tokens ~= nil
          end,
        },
      },
    },
    -- Custom `on_attach` run after the default AstroLSP one
    on_attach = function(client, bufnr)
      -- highlight other usages of the symbol under the cursor (like VSCode)
      if client:supports_method "textDocument/documentHighlight" then
        local group = vim.api.nvim_create_augroup("AstroLSPDocumentHighlight_" .. bufnr, { clear = true })
        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
          group = group,
          buffer = bufnr,
          callback = function() vim.lsp.buf.document_highlight() end,
        })
        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufLeave" }, {
          group = group,
          buffer = bufnr,
          callback = function() vim.lsp.buf.clear_references() end,
        })
      end
    end,
  },
}
