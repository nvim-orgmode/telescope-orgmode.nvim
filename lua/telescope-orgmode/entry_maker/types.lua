
---@class MatchEntry
---@field value OrgHeadlineEntry | OrgFileEntry
---@field ordinal string
---@field filename string
---@field lnum number
---@field display function
---@field location string,
---@field line string,
---@field tags string,

---@class OrgHeadlineEntry
---@field file OrgApiFile
---@field filename string
---@field headline OrgApiHeadline
---@field properties table<string, string>

---@class OrgFileEntry
---@field file OrgApiFile
---@field filename string
---@field title string?
