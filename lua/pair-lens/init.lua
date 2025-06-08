local Client = require("pair-lens.client")
local config = require("pair-lens.config")

local M = {}

M.client = nil

---@param opts? PairLensConfig
function M.setup(opts)
  config.setup(opts)

  if not M.client then
    M.client = Client.new()
  end

  M.client:setup()
end

function M.get_client()
  return M.client
end

return M
