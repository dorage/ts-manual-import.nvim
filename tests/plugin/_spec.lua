local plugin = require("ts-manual-import")

describe("setup", function()
  it("works with default", function()
    assert(1 == 1, "must equal")
    -- assert(plugin.hello() == "Hello!", "my first function with param = Hello!")
  end)

  it("works with custom var", function()
    -- plugin.setup({ opt = "custom" })
    -- assert(plugin.hello() == "custom", "my first function with param = custom")
    assert(1 ~= 0, "must not equal")
  end)
end)
