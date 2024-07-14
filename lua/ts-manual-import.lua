local import = require("ts-manual-import.module")

local M = {}

---import modules under the last import statement in the buffer
---@param imports Import[]
M.import = function(imports)
  vim.schedule(function()
    import.restore_cursor(import.set_import_statements)(imports)
  end)
end

---import modules under the last import statement in the buffer
---@param imports Import[]
M.luasnip_callback = function(imports)
  return {
    [-1] = {
      [require("luasnip.util.events").enter] = function()
        M.import(imports)
      end,
    },
  }
end

return M
