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
local function get_parsed_import_statements()
  ---@type Import[]
  local import_map = {}
  local import_statements = get_import_statements()

  -- parse import statements
  for _, import_stmt in ipairs(import_statements) do
    local source_nodes = search_node(import_stmt, function(node)
      return node:type() == "string_fragment"
    end)
    local module_nodes = search_node(import_stmt, function(node)
      return node:type() == "identifier" and node:parent():type() == "import_specifier"
    end)
    local default_module_nodes = search_node(import_stmt, function(node)
      return node:type() == "identifier" and node:parent():type() == "import_clause"
    end)

    local source = get_text_by_range(source_nodes[1]:range())
    local modules = fp.map(module_nodes, function(node)
      return get_text_by_range(node:range())
    end)
    local default_modules = fp.map(default_module_nodes, function(node)
      return get_text_by_range(node:range())
    end)

    import_map[#import_map + 1] =
      { node = import_stmt, source = source, modules = modules, default_modules = default_modules }
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
---@param imports Import[]
M.set_import_statements = function(imports)
  -- TODO:
  -- get import statements in the current buffer
  -- add imports into existed import statements

  -- local import_stmts = get_import_statements()
  local parsed_import_stmts = get_parsed_import_statements()
  -- preserve cursor position
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))

  for _, import in ipairs(imports) do
    local matched_import_stmts = fp.filter(parsed_import_stmts, function(import_stmt)
      return import_stmt.source == import.source
    end)

    -- if the import statement, has same source, does not exist
    if matched_import_stmts[#matched_import_stmts] == nil then
      local last_import_stmt = parsed_import_stmts[#parsed_import_stmts]
      -- if there has no import statement
      if last_import_stmt == nil then
        local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)

        vim.api.nvim_buf_set_lines(0, 0, 1, false, fp.combine({ gen_import_statement(import), "" }, first_line))
        -- add below of the last import statement
      else
        local start_row, _, end_row = last_import_stmt.node:range()
        local last_import_stmt_lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
        vim.api.nvim_buf_set_lines(
          0,
          start_row,
          end_row + 1,
          false,
          fp.combine(last_import_stmt_lines, { gen_import_statement(import), "" })
        )
      end
      -- line had added
      row = row + 1
      goto continue
    end

    local existed_modules = fp.pipe(
      fp.pipe_curry(fp.map, function(import_stmt)
        return import_stmt.modules
      end),
      unpack,
      fp.combine
    )(matched_import_stmts)

    local existed_default_modules = fp.pipe(
      fp.pipe_curry(fp.map, function(import_stmt)
        return import_stmt.default_modules
      end),
      unpack,
      fp.combine
    )(matched_import_stmts)

    local missing_modules = fp.filter(import.modules, function(module)
      return not fp.some(existed_modules, function(existed_module)
        return module == existed_module
      end)
    end)

    local missing_default_modules = fp.filter(import.default, function(module)
      return not fp.some(existed_default_modules, function(existed_default_module)
        return module == existed_default_module
      end)
    end)

    local last_import_stmt = matched_import_stmts[#matched_import_stmts]
    local start_row, _, end_row = last_import_stmt.node:range()

    vim.api.nvim_buf_set_lines(0, start_row, end_row + 1, false, {
      gen_import_statement({
        source = import.source,
        default_modules = fp.combine(last_import_stmt.default, missing_default_modules),
        modules = fp.combine(last_import_stmt.modules, missing_modules),
      }),
    })

    ::continue::
  end
end

return M
