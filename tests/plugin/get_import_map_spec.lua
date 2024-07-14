local test_utils = require("tests.utils")
local fp = require("ts-manual-import.util")
local module = require("ts-manual-import.module")

local function compare_arr(arr1, arr2)
  arr1 = arr1 ~= nil and arr1 or {}
  table.sort(arr1)
  arr2 = arr2 ~= nil and arr2 or {}
  table.sort(arr2)

  return table.concat(arr1, ",") == table.concat(arr2, ",")
end

---
---@param import_map ImportMap
---@param expected_import Import
local assert_import_map = function(import_map, expected_import)
  test_utils.assert(import_map, expected_import, function(result, expected)
    return fp.some(result, function(value, index, array)
      return value.source == expected.source
        and value.default == expected.default
        and compare_arr(value.modules, expected.modules)
    end)
  end)
end

describe("get import map", function()
  before_each(function()
    vim.cmd("edit tests/ts/import_map.ts")
  end)

  after_each(function()
    vim.cmd("u0")
    vim.cmd("bd")
  end)

  it("should return correct import map", function()
    local import_map = module.get_import_map()

    assert_import_map(import_map, { source = "source-only" })
    assert_import_map(import_map, { source = "default-only", default = "A" })
    assert_import_map(import_map, { source = "default-with-a-module", default = "B", modules = { "useB" } })
    assert_import_map(import_map, { source = "default-with-modules", default = "C", modules = { "useC", "useCC" } })
    assert_import_map(import_map, { source = "a-module", modules = { "useD" } })
    assert_import_map(import_map, { source = "modules", modules = { "useE", "useEE" } })
  end)
end)
