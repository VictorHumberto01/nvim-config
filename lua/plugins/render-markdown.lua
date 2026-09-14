return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" },
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {},
  keys = {
    {
      "<leader>mp",
      "<cmd>RenderMarkdown preview<cr>",
      ft = { "markdown" },
      desc = "Markdown Preview Split (dentro do Vim)",
    },
  },
}
