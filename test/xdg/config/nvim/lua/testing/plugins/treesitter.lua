return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					"javascript",
					"typescript",
					"tsx",
				},
				indent = {
					enable = true,
				},
				sync_install = true,
				auto_install = true,
			})
		end,
	},
}
