require "dotenv".config()

local config = {
    name = "you_name",
    token = os.getenv("GITHUB_TOKEN") or nil
}

return config
