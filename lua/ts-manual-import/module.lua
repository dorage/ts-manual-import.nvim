---------------------------------------------------------------------------------------
--
-- import modules
--
---------------------------------------------------------------------------------------

local fp = require("ts-manual-import.util")

---------------------------------------------------------------------------------------
--
-- define type hints
--
---------------------------------------------------------------------------------------

---@class Import
---@field source string
---@field modules string[]?
---@field default string?

---@class ImportMap: Import
---@field node TSNode

---@class TSPathNode
---@field [1] TSNode
---@field [2] integer

---------------------------------------------------------------------------------------
--
-- functions
--
---------------------------------------------------------------------------------------

---return root of AST
---@return TSNode
local function get_curr_bufr_root()
  local parser = vim.treesitter.get_parser()
  local tree = parser:parse()
  local root = tree[1]:root()

  return root
end

---return the text that the range indicates
---@param start_row integer
---@param start_col integer
---@param end_row integer
---@param end_col integer
---@return string
local function get_text_by_range(start_row, start_col, end_row, end_col)
  return (vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {}))[1]
end

--- find a node by condition under node
--- @param node TSNode
--- @param condition fun(node:TSNode): boolean
---@return TSNode[]
local function search_node(node, condition)
  local found = {}

  if condition(node) then
    found = { node }
  end

  for child in node:iter_children() do
    local new_found = search_node(child, condition)
    for _, value in pairs(new_found) do
      found[#found + 1] = value
    end
  end

  return found
end

---get import statement nodes
---@return TSNode[]
local function get_import_statements()
  local root = get_curr_bufr_root()

  -- get import statements
  local import_statements = {}
  for child in root:iter_children() do
    if child:type() == "import_statement" then
      import_statements[#import_statements + 1] = child
    end
  end
  return import_statements
end

---find all import statements in the current buffer and return them in ImportMap array
---@return ImportMap[]
local function get_import_map()
  ---@type Import[]
  local import_map = {}
  local import_stmt_nodes = get_import_statements()

  -- parse import statements
  for _, import_stmt_node in ipairs(import_stmt_nodes) do
    local source_nodes = search_node(import_stmt_node, function(node)
      return node:type() == "string_fragment"
    end)
    local module_nodes = search_node(import_stmt_node, function(node)
      return node:type() == "identifier" and node:parent():type() == "import_specifier"
    end)
    local default_nodes = search_node(import_stmt_node, function(node)
      return node:type() == "identifier" and node:parent():type() == "import_clause"
    end)

    local source = get_text_by_range(source_nodes[1]:range())
    local modules = module_nodes[#module_nodes] ~= nil
        and fp.map(module_nodes, function(node)
          return get_text_by_range(node:range())
        end)
      or nil
    local default = default_nodes[1] ~= nil and get_text_by_range(default_nodes[1]:range()) or nil

    import_map[#import_map + 1] = { node = import_stmt_node, source = source, modules = modules, default = default }
  end

  return import_map
end

---comment
---@param ts_node TSNode
---@return TSPathNode[]
local function get_ts_path(ts_node)
  local ts_path = {}
  local cursor = ts_node

  if cursor == nil then
    return ts_path
  end

  local parent = cursor:parent()
  while parent ~= nil do
    local n = 0
    for child in parent:iter_children() do
      -- find cursor n th
      if child:type() == cursor:type() then
        if child:id() == cursor:id() then
          goto continue
        end
        n = n + 1
      end
    end
    ::continue::
    ts_path = fp.combine({ { cursor, n } }, ts_path)
    cursor = parent
    parent = cursor:parent()
  end

  return ts_path
end

---comment
---@param ts_path TSPathNode[]
---@return TSNode
local function find_ts_node(ts_path)
  local cursor = get_curr_bufr_root()

  for _, ts_path_node in ipairs(ts_path) do
    local ts_node, ts_nth = unpack(ts_path_node)
    local n = 0
    for child in cursor:iter_children() do
      if child:type() == ts_node:type() then
        if n == ts_nth then
          cursor = child
          goto continue
        end
        n = n + 1
      end
    end
    ::continue::
  end

  return cursor
end

---generate import statement string
---@param import Import
---@return string
local function gen_import_statement(import)
  ---comment
  ---@param module_stmt string?
  ---@return string
  local import_stmt_wrapper = function(module_stmt)
    if module_stmt == nil then
      return "import " .. "'" .. import.source .. "';"
    end
    return "import " .. module_stmt .. " from '" .. import.source .. "';"
  end

  -- to make condition easier
  if import.modules ~= nil and import.modules[#import.modules] == nil then
    import.modules = nil
  end

  -- return source only
  if import.default == nil and import.modules == nil then
    return import_stmt_wrapper()
  end

  local module_stmt = ""

  -- add default modules
  if import.default ~= nil then
    module_stmt = module_stmt .. import.default

    if import.modules == nil then
      return import_stmt_wrapper(module_stmt)
    end

    module_stmt = module_stmt .. ", "
  end

  module_stmt = module_stmt .. "{ " .. table.concat(import.modules, ", ") .. " }"
  return import_stmt_wrapper(module_stmt)
end

---------------------------------------------------------------------------------------
--
-- module interfaces
--
---------------------------------------------------------------------------------------

local M = {}

M.gen_import_statement = gen_import_statement
M.get_import_map = get_import_map

---comment
---@param fn function
M.restore_cursor = function(fn)
  return function(...)
    local args = { ... }
    local start_node = vim.treesitter.get_node()
    if start_node == nil then
      start_node = get_curr_bufr_root()
    end
    local ts_path = get_ts_path(start_node)
    local start_node_row = start_node:range()
    local start_cursor_row, start_cursor_col = unpack(vim.api.nvim_win_get_cursor(0))

    fn(unpack(args))

    local final_node = find_ts_node(ts_path)
    local final_node_row = final_node:range()
    vim.api.nvim_win_set_cursor(0, {
      final_node_row + (start_cursor_row - start_node_row),
      start_cursor_col,
    })
  end
end

---set new import statements in the current buffer
---@param new_imports Import[]
M.set_import_statements = function(new_imports)
  -- TODO:
  -- get import statements in the current buffer
  -- add imports into existed import statements

  for _, new_import in ipairs(new_imports) do
    local existing_imports = get_import_map()
    -- if import statement is empty
    -- then add import statements in the top of the file
    -- return
    if existing_imports[#existing_imports] == nil then
      local curr_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)
      vim.api.nvim_buf_set_lines(0, 0, 1, false, { gen_import_statement(new_import), unpack(curr_line) })
      goto continue
    end

    local same_source_imports = fp.filter(existing_imports, function(existing_import)
      return existing_import.source == new_import.source
    end)

    -- if import statement exists
    -- but not overlapped sources
    -- then add import statement below of the last import statement
    -- return
    if same_source_imports[#same_source_imports] == nil then
      local last_import_stmt = existing_imports[#existing_imports]
      local start_row, _, end_row = last_import_stmt.node:range()
      local last_import_stmt_lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)

      vim.api.nvim_buf_set_lines(
        0,
        start_row,
        end_row + 1,
        false,
        fp.combine(last_import_stmt_lines, { gen_import_statement(new_import) })
      )
      -- line had added
      goto continue
    end

    -- but overlap sources
    -- then find unique modules, and add it in the last import statement

    local missing_default = nil

    if new_import.default ~= nil then
      local existing_default = fp.pipe(
        fp.pipe_curry(fp.map, function(import_map)
          return import_map.default_modules
        end),
        unpack,
        fp.combine
      )(same_source_imports)

      if existing_default[#existing_default] == nil then
        missing_default = new_import.default
      end
    end

    local missing_modules = {}

    if new_import.modules ~= nil and new_import.modules[#new_import.modules] ~= nil then
      local existing_modules = fp.pipe(
        fp.pipe_curry(fp.map, function(import_map)
          return import_map.modules
        end),
        unpack,
        fp.combine
      )(same_source_imports)

      missing_modules = fp.filter(new_import.modules, function(module)
        return not fp.some(existing_modules, function(existing_module)
          return module == existing_module
        end)
      end)
    end

    local last_import_stmt = same_source_imports[#same_source_imports]
    local start_row, _, end_row = last_import_stmt.node:range()

    vim.api.nvim_buf_set_lines(0, start_row, end_row + 1, false, {
      gen_import_statement({
        source = new_import.source,
        default_modules = missing_default ~= nil and missing_default or last_import_stmt.default,
        modules = fp.combine(last_import_stmt.modules, missing_modules),
      }),
    })

    ::continue::
  end
end

return M
