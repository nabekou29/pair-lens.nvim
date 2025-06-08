---@class PairLensConfig
---@field enabled boolean Whether the plugin is enabled
---@field style PairLensStyleConfig Virtual text styling configuration
---@field disable_filetypes string[] List of filetypes to disable the plugin for
---@field min_lines number Minimum lines to show virtual text
---@field custom_queries table<string, string> Custom queries for specific filetypes

---@class PairLensStyleConfig
---@field format string|fun(info: PairLensNodeInfo):string|string[][] Format string or function for virtual text (function should return string|string[][])
---@field hl string Highlight group for virtual text

---@class PairLensNodeInfo
---@field start_line number Start line number (1-indexed)
---@field end_line number End line number (1-indexed)
---@field start_text string Text of the start line
---@field end_text string Text of the end line
---@field line_count number Number of lines in the node
---@field node_text string Text content of the node
---@field bufnr number Buffer number
---@field node_type string Type of the treesitter node
---@field lang string Language/filetype of the buffer

---@class PairLensClient
---@field namespace number Namespace for virtual text
---@field buffers table<number, boolean> Active buffers
---@field autocmd_group number|nil Autocmd group ID

return {}
