local ok, config = pcall(require, "config_local")
if not ok then
    config = require("config")
end

local Logger = require("src.logger")
local logger = Logger.new("logs.txt", "WARN")

logger:error("test")