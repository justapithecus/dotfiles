return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}

      if vim.fn.executable("gopls") == 1 then
        opts.servers.gopls = opts.servers.gopls or {}
      end

      if vim.fn.executable("clangd") == 1 then
        opts.servers.clangd = opts.servers.clangd or {}
      end

      if vim.fn.executable("rust-analyzer") == 1 then
        opts.servers.rust_analyzer = opts.servers.rust_analyzer or {}
      end
    end,
  },
}
