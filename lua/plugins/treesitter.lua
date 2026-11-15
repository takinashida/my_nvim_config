-- Customize Treesitter
-- Treesitter customizations are handled with AstroCore
-- (nvim-treesitter simply provides a download utility for parsers)

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    treesitter = {
      highlight = true, -- treesitter based highlighting
      indent = true, -- treesitter based indentation
      auto_install = true, -- install parsers for detected filetypes on the fly
      ensure_installed = {
        "rust",
        "toml",
        "lua",
        "luadoc",
        "vim",
        "vimdoc",
        "query",
        "markdown",
        "markdown_inline",
        "json",
        "yaml",
        "bash",
        "c",
        "comment",
        "regex",
      },
    },
  },
}
