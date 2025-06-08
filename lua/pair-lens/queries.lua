local M = {}

local javascript = [[
  (function_declaration) @function
  (class_declaration) @class
  (method_definition) @method
  (if_statement) @if
  (for_statement) @for
  (while_statement) @while
  (try_statement) @try
  (arrow_function) @arrow
  (object) @object
]]

local typescript = javascript .. [[
  (interface_declaration) @interface
  (object_type) @object
]]

local jsx = javascript
  .. [[
  (jsx_element) @jsx_element
  (jsx_opening_element) @jsx_opening_element
]]

local tsx = typescript
  .. [[
  (jsx_element) @jsx_element
  (jsx_opening_element) @jsx_opening_element
]]

local json = [[
  (pair) @pair
]]

local jsonc = json

M.default_queries = {
  lua = [[
    (function_definition) @function
    (if_statement) @if
    (for_statement) @for
    (while_statement) @while
    (repeat_statement) @repeat
    (do_statement) @do
  ]],

  javascript = javascript,
  typescript = typescript,
  jsx = jsx,
  tsx = tsx,
  json = json,
  jsonc = jsonc,

  yaml = [[
    (block_mapping_pair) @pair
  ]],

  python = [[
    (function_definition) @function
    (class_definition) @class
    (if_statement) @if
    (for_statement) @for
    (while_statement) @while
    (try_statement) @try
    (with_statement) @with
  ]],

  ruby = [[
    (method) @method
    (class) @class
    (module) @module
    (if) @if
    (unless) @unless
    (while) @while
    (until) @until
    (for) @for
    (begin) @begin
    (do_block) @do_block
  ]],

  rust = [[
    (function_item) @function
    (impl_item) @impl
    (struct_item) @struct
    (enum_item) @enum
    (trait_item) @trait
    (mod_item) @mod
    (loop_expression) @loop
    (while_expression) @while
    (for_expression) @for
    (if_expression) @if
    (match_expression) @match
  ]],

  go = [[
    (function_declaration) @function
    (method_declaration) @method
    (type_declaration) @type
    (if_statement) @if
    (for_statement) @for
    (switch_statement) @switch
    (select_statement) @select
  ]],
}

function M.get_query(lang, custom_queries)
  if custom_queries and custom_queries[lang] then
    return custom_queries[lang]
  end

  return M.default_queries[lang]
end

function M.parse_query(lang, query_string)
  if not query_string then
    return nil
  end

  local ok, query = pcall(vim.treesitter.query.parse, lang, query_string)
  if not ok then
    vim.notify(
      "pair-lens: Failed to parse query for " .. lang .. ": " .. query,
      vim.log.levels.WARN
    )
    return nil
  end

  return query
end

function M.get_parsed_query(lang, custom_queries)
  local query_string = M.get_query(lang, custom_queries)
  if not query_string then
    return nil
  end

  return M.parse_query(lang, query_string)
end

return M
