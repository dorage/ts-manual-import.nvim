local module = require("ts-manual-import.module")

describe("generate import statement", function()
  it("a default_module", function()
    local import_stmt = module.gen_import_statement({ default = "React", source = "react" })
    local expected = "import React from 'react';"

    assert(import_stmt == expected, "must equals to expected")
  end)

  it("a default_module with a module", function()
    local import_stmt = module.gen_import_statement({ default = "React", modules = { "useState" }, source = "react" })
    local expected = "import React, { useState } from 'react';"

    assert(import_stmt == expected, "must equals to expected")
  end)

  it("a default_module with multiple modules", function()
    local import_stmt = module.gen_import_statement({
      default = "React",
      modules = { "useState", "useEffect" },
      source = "react",
    })
    local expected = "import React, { useState, useEffect } from 'react';"

    assert(import_stmt == expected, "must equals to expected")
  end)

  it("a module", function()
    local import_stmt = module.gen_import_statement({ modules = { "useState" }, source = "react" })
    local expected = "import { useState } from 'react';"

    assert(import_stmt == expected, "must equals to expected")
  end)

  it("multiple modules", function()
    local import_stmt = module.gen_import_statement({ modules = { "useState", "useEffect" }, source = "react" })
    local expected = "import { useState, useEffect } from 'react';"

    assert(import_stmt == expected, "must equals to expected")
  end)
end)
