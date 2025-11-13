# langstat

langstat is a lightweight Lua-based CLI tool that analyzes programming language usage across your public GitHub repositories.

It is a small utility written in Lua to quickly visualize language distribution for any GitHub user.

## ✨ Features

* Fetches all public repositories of a GitHub user
* Aggregates language usage using the official GitHub API
* Displays language share visually using text-based bar charts
* Supports optional CLI flags:

  * `-h`, `--help` — show usage
  * `-r N`, `--row-counts N` — show the top **N** languages
* Configurable via `config.lua` or `config_local.lua`
* Logs errors to file

## 💻 Installation

Clone the repository:

```bash
git clone https://github.com/yourname/langstat.git
cd langstat
```

Install Lua dependencies:

* Lua 5.1+ or LuaJIT
* `luasec` for HTTPS requests
* `dkjson` for JSON parsing
* `dotenv` for loading environment variables

Install dependencies using LuaRocks:

```bash
luarocks install luasec
luarocks install dkjson
luarocks install dotenv
```

> `ltn12` is included with LuaSocket, which often comes bundled with Lua distributions.

## ⚙️ Configuration

Create a `.env` file in the project root:

```
GITHUB_TOKEN=your_github_token
```

Copy and adjust `config.lua`:

```lua
require("dotenv").config()

local config = {
    name = "your_github_username",
    token = os.getenv("GITHUB_TOKEN") or nil,
    log_level = "ERROR"
}

return config
```

### About GitHub tokens

* If you do not provide a token, GitHub allows **60 API requests per hour**.
* With a personal access token, the limit increases to **5000 requests per hour**.
* If your user has many repositories, it is recommended to provide a token to avoid hitting rate limits.
* You can create a personal access token in GitHub Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token (no scopes needed for public repo access).

## ▶️ Usage

Run the tool:

```bash
lua main.lua
```

Show help:

```bash
lua main.lua --help
```

Show only the top 5 languages:

```bash
lua main.lua -r 5
```

Example output:

```
============================================
langstat — GitHub Language Statistics
User: ugolnikovE
Generated at: 2025-11-13 23:16:58
============================================
Lua              █████████░░░░░░░░░░░ 47.93%
C                █████████░░░░░░░░░░░ 45.12%
CMake            █░░░░░░░░░░░░░░░░░░░  6.62%
Dockerfile       ░░░░░░░░░░░░░░░░░░░░  0.34%
```

## 🗂 Project Structure

```
.
├── src/
│   ├── github_api.lua
│   ├── language_analytics.lua
│   └── logger.lua
├── tests/
│   ├── github_agent_spec.lua
│   └── language_analytics_spec.lua
├── config.lua
├── main.lua
├── README.md
├── LICENSE
└── .gitignore
```

## 💡 Motivation

This project was created to experiment with Lua and build a simple tool to visualize programming language usage in GitHub repositories.

## 📄 License

This project is licensed under the MIT License — see `LICENSE` for details.
