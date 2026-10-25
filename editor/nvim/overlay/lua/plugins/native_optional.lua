local has_make = vim.fn.executable("make") == 1
local has_cmake = vim.fn.executable("cmake") == 1
local has_cc = (vim.fn.executable("cc") == 1) or (vim.fn.executable("gcc") == 1) or (vim.fn.executable("clang") == 1)
local can_build_c = (has_cc and (has_make or has_cmake))

local has_cargo = vim.fn.executable("cargo") == 1
local can_build_rust = has_cargo

return {
  { "nvim-treesitter/nvim-treesitter", enabled = can_build_c },
  { "nvim-telescope/telescope-fzf-native.nvim", enabled = can_build_c, build = "make" },

  -- If you later add any Rust-native plugins, gate them like this:
  -- { "SOME/RUST_PLUGIN", enabled = can_build_rust, build = "cargo build --release" },
}
