return {
  "github/copilot.vim",
  name = "copilot.vim",
  enabled = true,
  event = "InsertEnter",
  config = function()
    -- Disable Copilot default mappings
    vim.g.copilot_no_tab_map = true

    -- Manual accept only
    vim.keymap.set("i", "<C-J>", 'copilot#Accept("<CR>")', {
      expr = true,
      replace_keycodes = false,
    })

    -- Dismiss suggestion
    vim.keymap.set("i", "<C-K>", "<Plug>(copilot-dismiss)")

    -- Restrict filetypes
    vim.g.copilot_filetypes = {
      markdown = false,
      gitcommit = false,
      yaml = false,
      json = false,
    }
  end,
}

