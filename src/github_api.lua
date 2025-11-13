-- Simple Lua wrapper for GitHub API
-- Description: Provides basic methods for interacting with GitHub API
--              (fetching repos, languages, rate limits) with unified request handling.

local https = require("ssl.https")
local json = require("dkjson")
local ltn12 = require("ltn12")

---@module GitHubAgent
local GitHubAgent = {}
GitHubAgent.__index = GitHubAgent

--- Constructor
---@param config table Configuration table: { name = string, token = string|nil }
---@param logger table Logger instance (must support :info() and :error())
---@return GitHubAgent
function GitHubAgent.new(config, logger)
        assert(config, "Config table is required")
        assert(config.name and config.name ~= "", "GitHub username must be provided in config.name")
        assert(logger, "Logger instance is required")

        local self = setmetatable({}, GitHubAgent)
        self.config = config
        self.logger = logger
        self.rate_limit = nil
        self.remaining_requests = nil
        self.rate_limit_reset = nil

        self.logger:info("GitHubAgent created successfully for user: " .. config.name)

        return self
end

--- Internal helper to make HTTPS requests to GitHub API and parse JSON response
---@param url string Full API URL
---@param method string|nil HTTP method (default "GET")
---@return table|nil data Parsed JSON response (or nil if failed)
---@return number|nil code HTTP status code
---@return string|nil err Error message if failed
function GitHubAgent:_request_json(url, method)
        method = method or "GET"
        local body = {}

        local request_headers = {
                ["User-Agent"] = "langstat-lua/0.1.0 (ugolnikovE)",
                ["Accept"] = "application/json"
        }

        if self.config.token then
                request_headers["Authorization"] = string.format("Bearer %s", self.config.token)
                self.logger:info("Using authorization token for request")
        else
                self.logger:info("No authorization token, using anonymous requests")
        end

        local res, code, headers, status = https.request({
                url = url,
                method = method,
                headers = request_headers,
                sink = ltn12.sink.table(body)
        })

        if not code then
                return nil, nil, "Network error: " .. tostring(status)
        end

        if code == 200 then
                local json_body = table.concat(body)
                local data, pos, err = json.decode(json_body)
                if err then
                        return nil, code, "JSON decode error: " .. err
                end

                if headers["x-ratelimit-remaining"] then
                        self.logger:info(string.format(
                                "RateLimit: %s/%s remaining (reset: %s)",
                                headers["x-ratelimit-remaining"],
                                headers["x-ratelimit-limit"],
                                os.date("%H:%M:%S", tonumber(headers["x-ratelimit-reset"]) or 0)
                        ))
                        self.rate_limit = tonumber(headers["x-ratelimit-limit"]) or 0
                        self.remaining_requests = tonumber(headers["x-ratelimit-remaining"]) or 0
                        self.rate_limit_reset = tonumber(headers["x-ratelimit-reset"]) or 0
                end

                return data, code, nil
        else
                return nil, code, string.format("HTTP %s - %s", code, status or "unknown")
        end
end

--- Fetch public repositories for a given username (single page)
---@param per_page number|nil Number of repositories per page (default 100)
---@param page_number number|nil Page number (default 1)
---@return table|nil data Array of repositories
---@return string|nil err Error message if failed
function GitHubAgent:get_repositories_by_username(per_page, page_number)
        per_page = per_page or 100
        page_number = page_number or 1

        local url = string.format(
                "https://api.github.com/users/%s/repos?per_page=%d&page=%d",
                self.config.name,
                per_page,
                page_number
        )

        self.logger:info(string.format(
                "Fetching %d repositories on page %d for user %s",
                per_page,
                page_number,
                self.config.name
        ))

        local data, code, err = self:_request_json(url)
        if not data then
                self.logger:error(err)
                return nil, err
        end
        return data, nil
end

--- Fetch all repositories for the configured username (handles pagination)
---@param per_page number|nil Number of repositories per page (default 100)
---@return table|nil all_repos Array of all repositories
---@return string|nil err Error message if failed
function GitHubAgent:get_all_repositories(per_page)
        per_page = per_page or 100
        local all_repos = {}
        local page = 1

        self.logger:info(string.format("Fetching all repositories for user '%s'...", self.config.name))

        while true do
                local repos, err = self:get_repositories_by_username(per_page, page)
                if not repos then
                        self.logger:error(string.format("Failed to fetch page %d: %s", page, err or "unknown"))
                        return all_repos, err
                end

                if #repos == 0 then
                        break
                end

                for _, repo in ipairs(repos) do
                        table.insert(all_repos, repo)
                end

                self.logger:info(string.format("Fetched page %d with %d repositories", page, #repos))
                page = page + 1
        end

        self.logger:info(string.format("Total repositories collected: %d", #all_repos))
        return all_repos, nil
end

--- Fetch language statistics for a specific repository
---@param reponame string Repository name
---@return table|nil data Language stats (bytes of code per language)
---@return string|nil err Error message if failed
function GitHubAgent:get_languages_in_repo(reponame)
        local url = string.format(
                "https://api.github.com/repos/%s/%s/languages",
                self.config.name,
                reponame
        )

        self.logger:info(string.format("Fetching %s repository languages", reponame))

        local data, code, err = self:_request_json(url)
        if not data then
                self.logger:error(err)
                return nil, err
        end
        return data, nil
end

--- Get current GitHub API rate limit info
---@return table|nil data Rate limit structure
---@return string|nil err Error message if failed
function GitHubAgent:get_rate_limit()
        local data, code, err = self:_request_json("https://api.github.com/rate_limit")
        if not data then
                self.logger:error(err)
                return nil, err
        end
        return data.rate or {}, nil
end

return GitHubAgent
