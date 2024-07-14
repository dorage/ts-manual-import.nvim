local plugin_dir = "tests/xdg/plugin/"

---extract repository name from github url
---@param url string
---@return string
local function extract_plugin_name(url)
  return url:match("([^/]+)$")
end

local M = {}

---comment
---@generic R
---@generic X
---@param result R
---@param expected X
---@param condition fun(result:R, expected:X):boolean
---@return unknown
M.assert = function(result, expected, condition)
  local v = condition(result, expected)
  local msg = "expected: " .. vim.inspect(expected) .. ", but got: " .. vim.inspect(result)
  return assert(v, msg)
end

---@class AddPluginOptions
---@field url string
---@field config function

---Add plugin, that will be used in tests
---@param options AddPluginOptions
M.add_plugin = function(options)
  local name = extract_plugin_name(options.url)
  print("adding " .. name .. "..")
  local dir = plugin_dir .. name
  local is_not_a_directory = vim.fn.isdirectory(dir) == 0
  if is_not_a_directory then
    vim.fn.system({ "git", "clone", options.url, dir })
  end
  vim.opt.rtp:append(dir)

  if options.config then
    options.config()
  end
  print("done")
end

M.busted = function()
  M.add_plugin({
    url = "https://github.com/nvim-lua/plenary.nvim",
    config = function()
      vim.opt.rtp:append(".")

      vim.cmd("runtime plugin/plenary.vim")
      require("plenary.busted")
    end,
  })
end

return M
