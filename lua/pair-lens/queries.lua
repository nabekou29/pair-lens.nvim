local M = {}

---@type table<string, string>
M.queries = {
  lua = [[
    [
      (function_definition) @function
      (function_declaration) @function
      (if_statement) @if
      (for_statement) @for
      (while_statement) @while
      (do_statement) @do
    ]
  ]],
  ruby = [[
    [
      (method) @method
      (if) @if
      (unless) @unless
      (while) @while
      (until) @until
      (for) @for
      (begin) @begin
      (class) @class
      (module) @module
      (do_block) @do
    ]
  ]],
  python = [[
    [
      (function_definition) @function
      (class_definition) @class
      (if_statement) @if
      (for_statement) @for
      (while_statement) @while
      (try_statement) @try
      (with_statement) @with
    ]
  ]],
  javascript = [[
    [
      (function_declaration) @function
      (class_declaration) @class
      (method_definition) @method
      (if_statement) @if
      (for_statement) @for
      (while_statement) @while
      (try_statement) @try
      (arrow_function) @arrow
    ]
  ]],
  typescript = [[
    [
      (function_declaration) @function
      (class_declaration) @class
      (method_definition) @method
      (if_statement) @if
      (for_statement) @for
      (while_statement) @while
      (try_statement) @try
      (arrow_function) @arrow
      (interface_declaration) @interface
      (enum_declaration) @enum
    ]
  ]],
  rust = [[
    [
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
    ]
  ]],
  go = [[
    [
      (function_declaration) @function
      (method_declaration) @method
      (type_declaration) @type
      (if_statement) @if
      (for_statement) @for
      (switch_statement) @switch
      (select_statement) @select
    ]
  ]],
}

---@param lang string
---@return string|nil
function M.get_query(lang)
  return M.queries[lang]
end

return M
