local plugin = require("ts-manual-import")

describe("setup", function()
	before_each(function()
		vim.cmd("edit tests/plugin_name/test.ts")
	end)

	after_each(function()
		vim.cmd("u0")
		vim.cmd("bd")
	end)

	it("works with default", function()
		assert(plugin.hello() == "Hello!", "my first function with param = Hello!")
	end)

	it("works with custom var", function()
		plugin.setup({ opt = "custom" })
		assert(plugin.hello() == "custom", "my first function with param = custom")
	end)

	it("get current buffer", function()
		plugin.setup({ opt = "custom" })
		assert(vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == 'console.log("test.ts desu");', "first line is this")
	end)
end)
