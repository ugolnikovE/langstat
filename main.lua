local ok, config = pcall(require, "config_local")
if not ok then
    config = require("config")
end

print(config.token)
print(config.name)
