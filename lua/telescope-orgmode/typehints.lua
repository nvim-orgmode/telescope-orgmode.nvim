-- Type-hints copied from nvim-orgmode to simplify development

---@class OrgFileMetadata
---@field mtime number
---@field changedtick number

---@class OrgFileOpts
---@field filename string
---@field lines string[]
---@field bufnr? number

---@class OrgFile
---@field filename string
---@field lines string[]
---@field content string
---@field metadata OrgFileMetadata
---@field parser vim.treesitter.LanguageTree
---@field root TSNode

---@class OrgApiFile
---@field category string current file category name. By default it's only filename without extension unless defined differently via #+CATEGORY directive
---@field filename string absolute path of the current file
---@field headlines OrgApiHeadline[]
---@field is_archive_file boolean
---@field get_link string
---@field private _file OrgFile
--
---@class OrgRange
---@field start_line number
---@field start_col number
---@field end_line number
---@field end_col number
---
---@class OrgHeadline
---@field headline TSNode
---@field file OrgFile

---@class OrgApiHeadline
---@field title string headline title without todo keyword, tags and priority. Ex. `* TODO I am a headline  :SOMETAG:` returns `I am a headline`
---@field line string full headline line
---@field level number headline level (number of asterisks). Example: 1
---@field todo_value? string todo keyword of the headline (Example: TODO, DONE)
---@field todo_type? 'TODO' | 'DONE' | ''
---@field tags string[] List of own tags
---@field deadline OrgDate|nil
---@field scheduled OrgDate|nil
---@field properties table<string, string> Table containing all properties. All keys are lowercased
---@field closed OrgDate|nil
---@field dates OrgDate[] List of all dates that are not "plan" dates
---@field position OrgRange
---@field all_tags string[] List of all tags (own + inherited)
---@field file OrgApiFile
---@field parent OrgApiHeadline|nil
---@field priority string|nil
---@field is_archived boolean headline marked with the `:ARCHIVE:` tag
---@field headlines OrgApiHeadline[]
---@field id_get_or_create number
---@field get_link string
---@field private _section OrgHeadline
---@field private _index number

---@class OrgApiRefileOpts
---@field source OrgApiHeadline
---@field destination OrgApiFile | OrgApiHeadline

---@class OrgApi
---@field load fun(name?: string|string[]): OrgApiFile|OrgApiFile[]
---@field current fun(): OrgApiFile
---@field refile fun(opts: OrgApiRefileOpts)
---@field insert_link fun(link_location: string): boolean
