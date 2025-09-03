return {
  "andymass/vim-matchup",
  event = "VeryLazy",
  config = function()
    -- vim.g.matchup_enabled = 0
    vim.g.matchup_matchparen_offscreen = { method = "status" }
    vim.g.matchup_matchparen_deferred = 1
    vim.g.matchup_matchparen_deferred_show_delay = 100
    vim.g.matchup_matchparen_hi_surround_always = 1
    vim.keymap.set("n", "<m-m>", "<cmd>MatchupWhereAmI<cr>", { noremap = true, silent = true })
  end,
}

-- TODO when install treesitter plugin copy in treesitter config
-- require'nvim-treesitter.configs'.setup {
--   matchup = {
--     enable = true,              -- mandatory, false will disable the whole extension
--     disable = { "c", "ruby" },  -- optional, list of language that will be disabled
--     -- [options]
--   },
-- }
