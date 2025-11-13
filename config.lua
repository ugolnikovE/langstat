-- Configuration file for LangStat
-- Loads GitHub username and token from environment variables or defaults.
require "dotenv".config() -- Load .env file if present

local config = {
        -- GitHub username (used for fetching repositories)
        name = "you_github_username",

        -- Optional GitHub personal access token for authenticated requests
        -- You can store it in a .env file as:
        -- GITHUB_TOKEN=ghp_yourtokenhere
        token = os.getenv("GITHUB_TOKEN") or nil,


        -- Logging level: "DEBUG", "INFO", "WARN", "ERROR"
        log_level = "ERROR"
}

return config
