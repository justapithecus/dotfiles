return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          mason = false,
          cmd = { "clangd" },
          filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
        },
        gopls = {
          mason = false,
          cmd = { "gopls" },
          filetypes = { "go", "gomod", "gowork", "gotmpl" },
        },
      },
    },
  },
}
