local GitHubAgent = require("github_api")

-- Fake logger for tests
local logger = {
        info = function() end,
        error = function() end
}

describe("GitHubAgent simple tests", function()
        local agent

        it("should create agent", function()
                agent = GitHubAgent.new({ name = "octocat" }, logger)
                assert.is_not_nil(agent)
                assert.is_equal(agent.config.name, "octocat")
        end)

        it("should fetch repositories (first page)", function()
                local repos, err = agent:get_repositories_by_username(5, 1)
                assert.is_nil(err)
                assert.is_table(repos)
                print("Fetched repos:", #repos)
        end)

        it("should fetch languages for a repo", function()
                local repos = agent:get_repositories_by_username(5, 1)
                if #repos > 0 then
                        local repo_name = repos[5].name
                        local langs, err = agent:get_languages_in_repo(repo_name)
                        assert.is_nil(err)
                        assert.is_table(langs)
                        print("Languages in", repo_name)
                        for lang, bytes in pairs(langs) do
                                print(string.format("  %s: %d bytes", lang, bytes))
                        end
                end
        end)

        it("should fetch rate limit info", function()
                local rate, err = agent:get_rate_limit()
                assert.is_nil(err)
                assert.is_table(rate)
                print("Rate limit info:")
                print(string.format("  Limit: %s", rate.limit or "n/a"))
                print(string.format("  Remaining: %s", rate.remaining or "n/a"))
                if rate.reset then
                        print("  Reset time:", os.date("%Y-%m-%d %H:%M:%S", rate.reset))
                end
        end)
end)
