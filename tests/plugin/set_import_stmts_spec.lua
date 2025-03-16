local test_utils = require("tests.utils")
local fp = require("ts-manual-import.util")
local module = require("ts-manual-import.module")

describe("add import statements", function()
  before_each(function() end)

  after_each(function()
    vim.cmd("u0")
    vim.cmd("bd")
  end)

  it("in the blank file", function()
    vim.cmd("edit tests/ts/blank.ts")
    module.set_import_statements({
      {
        source = "react",
        modules = { "useState" },
      },
      {
        source = "remix",
        modules = { "useLoaderData" },
      },
    })

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local expected = {
      "import { useState } from 'react';",
      "import { useLoaderData } from 'remix';",
      "",
    }

    test_utils.assert(lines, expected, function(result, expected)
      return fp.every(result, function(value, index, array)
        return value == expected[index]
      end)
    end)
  end)

  it("in the file, that have no import statements", function()
    vim.cmd("edit tests/ts/no-import.ts")
    module.set_import_statements({
      {
        source = "react",
        modules = { "useState" },
      },
      {
        source = "remix",
        modules = { "useLoaderData" },
      },
    })

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local expected = {
      "import { useState } from 'react';",
      "import { useLoaderData } from 'remix';",
      'console.log("hello no-import");',
    }

    test_utils.assert(lines, expected, function(result, expected)
      return fp.every(result, function(value, index, array)
        return value == expected[index]
      end)
    end)
  end)

  it("in the file, that have import statements, but sources are not overlapped", function()
    vim.cmd("edit tests/ts/unique-source.ts")
    module.set_import_statements({
      {
        source = "react",
        modules = { "useState" },
      },
      {
        source = "remix",
        modules = { "useLoaderData" },
      },
    })

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local expected = {
      'import { unique } from "unique-import";',
      "import { useState } from 'react';",
      "import { useLoaderData } from 'remix';",
    }

    test_utils.assert(lines, expected, function(result, expected)
      return fp.every(result, function(value, index, array)
        return value == expected[index]
      end)
    end)
  end)

  it("in the file, that have import statements, but sources are overlapped", function()
    vim.cmd("edit tests/ts/same-source.ts")
    module.set_import_statements({
      {
        source = "react",
        modules = { "useState" },
      },
      {
        source = "remix",
        modules = { "useLoaderData" },
      },
    })

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local expected = {
      "import { useEffect, useState } from 'react';",
      "import { useLoaderData } from 'remix';",
    }

    test_utils.assert(lines, expected, function(result, expected)
      return fp.every(result, function(value, index, array)
        return value == expected[index]
      end)
    end)
  end)

  it("in the file, that have import statements in multiple lines, but sources are overlapped", function()
    vim.cmd("edit tests/ts/same-module.ts")
    module.set_import_statements({
      {
        source = "react",
        modules = { "useState" },
      },
      {
        source = "remix",
        modules = { "useLoaderData" },
      },
    })

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local expected = {
      "import { useState, useEffect } from 'react';",
      "import { useLoaderData } from 'remix';",
    }

    test_utils.assert(lines, expected, function(result, expected)
      return fp.every(result, function(value, index, array)
        return value == expected[index]
      end)
    end)
  end)

  it("in the file, that have named module and default module in a import statements", function()
    vim.cmd("edit tests/ts/default-with-named.ts")
    module.set_import_statements({
      {
        source = "default-with-named",
        modules = { "named2" },
      },
    })

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local expected = {
      "import Default, { named1, named2 } from 'default-with-named';",
    }

    test_utils.assert(lines, expected, function(result, expected)
      return fp.every(result, function(value, index, array)
        return value == expected[index]
      end)
    end)
  end)
end)
