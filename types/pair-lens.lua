---@class PairLens.Config
---@field enabled boolean
---@field style PairLens.Style
---@field disable_filetypes string[]

---@class PairLens.Style
---@field format string
---@field hl string

---@class PairLens.PairInfo
---@field start_line_number number 開始行番号
---@field start_line_text string 開始行の文字列
---@field end_line_number number 終了行番号
---@field end_line_text string 終了行の文字列

---@class PairLens
---@field setup fun(opts?: PairLens.Config)
