local pick = require("mini.pick")
local headings = require("telescope-orgmode.mini.headings")
local refile_header = require("telescope-orgmode.mini.refile")
local insert_link = require("telescope-orgmode.mini.insert_link")
local search_tags = require("telescope-orgmode.mini.search_tags")

pick.registry["orgmode_headings"] = headings.start_picker
pick.registry["orgmode_refile_header"] = refile_header.refile_heading
pick.registry["orgmode_insert_link"] = insert_link.insert_link
pick.registry["orgmode_search_tags"] = search_tags.search_tags
