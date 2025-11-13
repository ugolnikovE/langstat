-- LanguageAnalyzer
-- Description: Analyzes languages in public GitHub repositories.
--              Collects raw byte statistics, sorts languages,
--              calculates percentages, and prints visual summaries.


---@module LanguageAnalyzer
local LanguageAnalyzer = {}
LanguageAnalyzer.__index = LanguageAnalyzer

--- Constructor
---@param agent table GitHubAgent instance used to fetch repository data
---@param logger table Logger instance (must support :info(), :warn(), :error())
---@return LanguageAnalyzer
function LanguageAnalyzer.new(agent, logger)
        assert(agent, "GithubAgent instance  is required")
        assert(logger, "Logger instance is required")

        local self = setmetatable({}, LanguageAnalyzer)
        self.logger = logger
        self.agent = agent
        self.language_raw_statistics = {}
        self.language_sorted_statistics = {}
        self.language_statistics_in_percents = {}
        self.total_bytes = 0

        logger:info("LanguageAnalyzer created successfully")

        return self
end

--- Adds language statistics from a single repository to the overall stats
---@param table table Key-value pairs of language -> bytes
function LanguageAnalyzer:_add_language_table(table)
        for language, bytes in pairs(table) do
                if type(bytes) == "number" then
                        self.language_raw_statistics[language] = (self.language_raw_statistics[language] or 0) + bytes
                        self.total_bytes = self.total_bytes + bytes
                end
        end
end

--- Sorts the language statistics in descending order by byte count
function LanguageAnalyzer:_generate_sort_language_table()
        local sorted_stats = {}

        for language, bytes in pairs(self.language_raw_statistics) do
                table.insert(sorted_stats, { language = language, bytes = bytes })
        end

        table.sort(sorted_stats, function(a, b)
                return a.bytes > b.bytes
        end)

        self.language_sorted_statistics = sorted_stats
end

--- Generates percentage statistics based on total bytes
function LanguageAnalyzer:_generate_language_stats_in_percents()
        local percent_stats = {}

        for _, item in ipairs(self.language_sorted_statistics) do
                local _percent = item.bytes / self.total_bytes * 100.0
                table.insert(percent_stats, { language = item.language, percent = _percent })
        end

        self.language_statistics_in_percents = percent_stats
end

--- Collects statistics across all repositories for the agent's user
---@param per_page number|nil Number of repositories to fetch per page (default 100)
---@return table|nil statistics Table of language percentages
---@return string|nil err Error message if failed
function LanguageAnalyzer:generate_statistic(per_page)
        local all_repos, err = self.agent:get_all_repositories(per_page)

        if err then
                self.logger:error(err)
                return nil, err
        end

        for _, repo in ipairs(all_repos) do
                local lang_table, err = self.agent:get_languages_in_repo(repo.name)
                if not lang_table then
                        self.logger:warn("Failed to get languages for repo: " ..
                                repo.name .. " (" .. tostring(err) .. ")")
                else
                        self:_add_language_table(lang_table)
                end
        end

        self:_generate_sort_language_table()

        if self.total_bytes == 0 then
                self.logger:warn("No language data collected")
                return nil, "No language data collected"
        end
        self:_generate_language_stats_in_percents()

        self.logger:info(string.format("Processed %d repositories, total bytes: %d", #all_repos, self.total_bytes))
        return self.language_statistics_in_percents, nil
end

--- Creates a single formatted string row for printing language stats
---@param lang string Language name
---@param percent number Percentage of total bytes
---@return string Formatted string row
function LanguageAnalyzer:_create_statistic_row(lang, percent)
        local s = ""
        local seg_count = math.floor(percent / 5)
        s = s .. string.format("%-16s", lang) .. " "
        s = s .. string.rep("█", seg_count) .. string.rep("░", 20 - seg_count)
        s = s .. " " .. string.format("%5.2f%%", percent)
        return s
end

--- Prints the collected language statistics as a visual table
function LanguageAnalyzer:print_statistic()
        for i, item in ipairs(self.language_statistics_in_percents) do
                print(self:_create_statistic_row(item.language, item.percent))
        end
end

return LanguageAnalyzer
