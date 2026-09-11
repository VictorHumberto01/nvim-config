return {
  "hisbaan/dataview.nvim",
  -- only load dataview.nvim for files in your obsidian vault
  event = {
    "BufEnter " .. vim.fn.expand("~") .. "/Notas/**",
  },
  -- configuration here, see below for full configuration options
  opts = {
    vault_dir = "~/Notas",
    buffer_type = "float", -- float | split | vsplit | tab
  },
}
