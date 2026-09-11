return {
  -- Popular colorschemes
  {
    "ellisonleao/gruvbox.nvim",
    lazy = true,
    opts = {
      transparent_mode = false,
    },
  },
  {
    "shaunsingh/nord.nvim",
    lazy = true,
  },
  {
    "neanias/everforest-nvim",
    lazy = true,
    opts = {
      background = "hard",
    },
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = true,
    opts = {
      variant = "auto",
      dark_variant = "main",
    },
  },
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
    opts = {
      theme = "wave",
    },
  },
  {
    "navarasu/onedark.nvim",
    lazy = true,
    opts = {
      style = "dark",
    },
  },

  -- Configure LazyVim to load the persisted theme on startup
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        local theme_file = vim.fn.stdpath("data") .. "/current_theme.txt"
        local theme = nil
        local f = io.open(theme_file, "r")
        if f then
          theme = vim.trim(f:read("*a") or "")
          f:close()
        end
        if not theme or theme == "" then
          local wall_file = vim.fn.stdpath("data") .. "/wallcolors.json"
          if vim.uv.fs_stat(wall_file) then
            theme = "wallcolors"
          else
            theme = "tokyonight"
          end
        end
        local ok = pcall(vim.cmd.colorscheme, theme)
        if not ok then
          pcall(vim.cmd.colorscheme, "tokyonight")
        end
      end,
    },
  },
}
