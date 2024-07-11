-- require("busted.runner")
local import = require("ts-manual-import.import")

describe("The stack data structure", function()
	describe("The empty stack", function()
		before_each(function() end)

		it("Can instantiate an empty stack", function()
			local import_stmt =
				import.gen_import_statement({ default_modules = {}, modules = { "useState" }, source = "react" })
			assert.is.equal(import_stmt, "import { useState } from 'react'")
		end)
	end)
end)
