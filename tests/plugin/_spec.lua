local fp = require("ts-manual-import.util")
local plugin = require("ts-manual-import")
local module = require("ts-manual-import.module")

describe("setup", function()
  before_each(function()
    vim.cmd("edit tests/blank.ts")
  end)

  after_each(function()
    vim.cmd("u0")
    vim.cmd("bd")
  end)

  it("works with default", function()
    module.add_import_statement({ { default_modules = { "React" }, modules = { "useState" }, source = "react" } })

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    print(fp.dump(lines))
    local expected = { "import React, { useState } from 'react'" }

    assert(
      fp.every(lines, function(line, index, array)
        return line == expected[index]
      end),
      "buffer must equals to expected"
    )
    -- assert(plugin.hello() == "Hello!", "my first function with param = Hello!")
  end)

  it("works with custom var", function()
    -- plugin.setup({ opt = "custom" })
    -- assert(plugin.hello() == "custom", "my first function with param = custom")
    assert(1 ~= 0, "must not equal")
  end)
end)
