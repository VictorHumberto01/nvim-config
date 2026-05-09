-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
vim.opt_local.relativenumber = false

-- Transparent background
local function transparent()
  local hl_groups = {
    "Normal",
    "NormalNC",
    "NormalFloat",
    "FloatBorder",
    "SignColumn",
    "LineNr",
    "CursorLineNr",
    "FoldColumn",
    "WinSeparator",
    "EndOfBuffer",
    "MsgArea",
  }
  for _, group in ipairs(hl_groups) do
    vim.api.nvim_set_hl(0, group, { bg = "none", ctermbg = "none" })
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = transparent,
})

transparent()

-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
