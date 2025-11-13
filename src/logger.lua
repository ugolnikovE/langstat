--- Logging module with levels (DEBUG, INFO, WARN, ERROR)
--- Provides a simple Logger with optional file output and log levels.
---@class Logger
local Logger = {}
Logger.__index = Logger

-- Table of log levels with priorities
---@type table<string, number>
local levels = { ["ERROR"] = 1, ["WARN"] = 2, ["INFO"] = 3, ["DEBUG"] = 4 }

--- Creates a new Logger instance
---@param file string Path to log file. Empty string "" means console only
---@param level string Minimum log level ("DEBUG", "INFO", "WARN", "ERROR")
---@return Logger Logger instance
function Logger.new(file, level)
        local self = setmetatable({}, Logger)
        self.file = file or ""
        self.level = level or "INFO"

        if file ~= "" then
                local ok, handle = pcall(io.open, file, "a")
                if ok and handle then
                        self.handle = handle
                else
                        print(string.format("[ERROR] Failed to open log file %s", file))
                end
        end

        return self
end

--- Sets the minimum logging level
---@param level string New log level
function Logger:setLevel(level)
        if levels[level] then
                self.level = level
        end
end

--- Logs a message if it meets the minimum level
---@param level string Level of the message ("DEBUG", "INFO", "WARN", "ERROR")
---@param msg string Message to log
function Logger:log(level, msg)
        if levels[level] <= levels[self.level] then
                local line = string.format("[%s][%s] %s\n", os.date("%Y-%m-%d %H:%M:%S"), level, msg)
                print(line)
                if self.handle then
                        local ok, err = pcall(function()
                                self.handle:write(line); self.handle:flush()
                        end)
                        if not ok then
                                print(string.format("[%s][ERROR] Failed to write log: %s\n", os.date("%Y-%m-%d %H:%M:%S"),
                                        err))
                        end
                end
        end
end

--- Logs a DEBUG message
---@param msg string Message to log
function Logger:info(msg)
        self:log("INFO", msg)
end

--- Logs an INFO message
---@param msg string Message to log
function Logger:warn(msg)
        self:log("WARN", msg)
end

--- Logs a WARN message
---@param msg string Message to log
function Logger:error(msg)
        self:log("ERROR", msg)
end

--- Logs an ERROR message
---@param msg string Message to log
function Logger:debug(msg)
        self:log("DEBUG", msg)
end

--- Closes the log file handle if it was opened
function Logger:close()
        if self.handle then
                self.handle:close()
                self.handle = nil
        end
end

return Logger
