local project_path = vim.fn.getcwd() .. "/"

return {
	{
		"ts-manual-import",
		dir = project_path,
		dev = true,
		config = function()
			vim.keymap.set({ "n" }, "<leader>n", function()
				require("ts-manual-import").import({
					{
						source = "@remix-run/node",
						modules = { "LoaderFunctionArgs", "json" },
						default_modules = {},
					},
				})
			end, { silent = true })
		end,
	},
}
