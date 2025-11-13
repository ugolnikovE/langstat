-- Load configuration
local ok, config = pcall(require, "config_local")
if not ok then
        config = require("config")
end

-- CLI argument parsing
local show_help = false
local row_count = nil

local i = 1
while i <= #arg do
        if arg[i] == "-h" or arg[i] == "--help" then
                show_help = true
                break
        elseif arg[i] == "-r" or arg[i] == "--row-counts" then
                local n = tonumber(arg[i + 1])
                if n then
                        row_count = n
                        i = i + 2
                else
                        print("Error: --row-counts requires a number")
                        i = i + 2
                end
        else
                i = i + 1
        end
end

if show_help then
        print("Usage: lua main.lua [options]")
        print("")
        print("  -h, --help            Show this help message")
        print("  -r, --row-counts N    Number of languages to display")
        os.exit(1)
end

-- Create Logger
local Logger = require("src.logger")
local logger = Logger.new("logs.txt", config.log_level)

-- Load modules
local GitHubAgent = require("src.github_api")
local LanguageAnalyzer = require("src.language_analytics")

-- Create GitHubAgent
local agent_ok, github_agent = pcall(GitHubAgent.new, config, logger)
if not agent_ok then
        logger:error("Failed to create GitHubAgent: " .. tostring(github_agent))
        logger:close()
        os.exit(1)
end

-- Create LanguageAnalyzer
local analyzer_ok, analyzer = pcall(LanguageAnalyzer.new, github_agent, logger)
if not analyzer_ok then
        logger:error("Failed to create LanguageAnalyzer: " .. tostring(analyzer))
        os.exit(1)
end

-- Generate Statistic
local stats, err = analyzer:generate_statistic(100)
if not stats then
        logger:error("Failed to generate statistics: " .. tostring(err))
        logger:close()
        os.exit(1)
end

print(string.rep("=", 44))
print("langstat — GitHub Language Statistics")
print(string.format("User: %s", config.name))
print(os.date("Generated at: %Y-%m-%d %H:%M:%S"))
print(string.rep("=", 44))
analyzer:print_statistic(row_count)

logger:close()
