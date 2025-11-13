local LanguageAnalyzer = require("language_analytics")

-- GitHubAgent Mock
local MockAgent = {}
MockAgent.__index = MockAgent

function MockAgent.new(repos, langs)
        local self = setmetatable({}, MockAgent)
        self.repos = repos or {}
        self.langs = langs or {}
        return self
end

function MockAgent:get_all_repositories()
        return self.repos, nil
end

function MockAgent:get_languages_in_repo(repo_name)
        return self.langs[repo_name] or {}, nil
end

-- Fake logger for tests
local logger = { info = function() end, warn = function() end, error = function() end }

describe("LanguageAnalyzer basic tests", function()
        local agent, analyzer

        before_each(function()
                agent = MockAgent.new(
                        { { name = "repo1" }, { name = "repo2" } },
                        { repo1 = { Lua = 1000, Python = 500 }, repo2 = { Python = 500, C = 200 } }
                )
                analyzer = LanguageAnalyzer.new(agent, logger)
        end)

        it("should create analyzer", function()
                assert.is_not_nil(analyzer)
                assert.is_table(analyzer.language_raw_statistics)
                assert.is_equal(analyzer.total_bytes, 0)
        end)

        it("should add language table correctly", function()
                analyzer:_add_language_table({ Lua = 100, Python = 50 })
                assert.is_equal(analyzer.language_raw_statistics.Lua, 100)
                assert.is_equal(analyzer.language_raw_statistics.Python, 50)
                assert.is_equal(analyzer.total_bytes, 150)
        end)

        it("should generate sorted language table", function()
                analyzer:_add_language_table({ Lua = 100, Python = 50, C = 200 })
                analyzer:_generate_sort_language_table()
                assert.is_equal(analyzer.language_sorted_statistics[1].language, "C")
                assert.is_equal(analyzer.language_sorted_statistics[2].language, "Lua")
                assert.is_equal(analyzer.language_sorted_statistics[3].language, "Python")
        end)

        it("should generate percentages correctly", function()
                analyzer:_add_language_table({ Lua = 100, Python = 50 })
                analyzer:_generate_sort_language_table()
                analyzer:_generate_language_stats_in_percents()
                assert.is_equal(analyzer.language_statistics_in_percents[1].language, "Lua")
                assert.is_equal(math.floor(analyzer.language_statistics_in_percents[1].percent), 66)
                assert.is_equal(analyzer.language_statistics_in_percents[2].language, "Python")
                assert.is_equal(math.floor(analyzer.language_statistics_in_percents[2].percent), 33)
        end)

        it("should generate full statistics", function()
                local stats, err = analyzer:generate_statistic()
                assert.is_nil(err)
                assert.is_table(stats)
                assert.is_true(#stats > 0)
                local languages = {}
                for _, item in ipairs(stats) do
                        languages[item.language] = item.percent
                end
                assert.is_not_nil(languages.Lua)
                assert.is_not_nil(languages.Python)
                assert.is_not_nil(languages.C)
        end)

        it("should create formatted row", function()
                local row = analyzer:_create_statistic_row("Lua", 50)
                assert.is_string(row)
                assert.is_not_nil(row:find("Lua"))
        end)
end)
