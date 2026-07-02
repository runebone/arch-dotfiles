return {
  "tpope/vim-dadbod",
  dependencies = {
    "kristijanhusak/vim-dadbod-ui",
    "kristijanhusak/vim-dadbod-completion",
  },
  config = function()
    vim.g.db_ui_save_location = "~/.local/share/db_ui"
    vim.g.db_ui_use_nerd_fonts = 1
    vim.g.dbs = {
      dev = os.getenv("DBUI_DEV"),
      stage = os.getenv("DBUI_STAGE"),
      prod = os.getenv("DBUI_PROD"),
    }
  end,
}
