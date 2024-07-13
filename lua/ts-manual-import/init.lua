local import = require("ts-manual-import.import")

local M = {}

---import modules under the last import statement in the buffer
---@param imports Import[]
M.import = function(imports)
	vim.schedule(function()
		import.restore_cursor(import.add_import_statement)(imports)
	end)
end

---import modules under the last import statement in the buffer
---@param imports Import[]
M.luasnip_callback = function(imports)
	return {
		[-1] = {
			[require("luasnip.util.events").enter] = function()
				vim.schedule(function()
					M.import(imports)
				end)
			end,
		},
	}
end

return M
