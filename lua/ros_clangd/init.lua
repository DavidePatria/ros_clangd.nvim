local utils = require "ros_clangd.utils"
local M = {}

CONFIG = {
  ws_json = true
}

function M.setup(config)
    for key, value in pairs(config) do
        if value ~= nil then
            ROS_CONFIG[key] = value
        end
    end
end

function M.ros_clangd()
  -- get path and pass it to the function that returns the workspace path
  local path = vim.fn.expand("%:p")

  return utils.verify_jsons(path)
end

return M
