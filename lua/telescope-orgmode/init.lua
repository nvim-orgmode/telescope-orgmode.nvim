local adapter = require('telescope-orgmode.adapters.telescope')
local config = require('telescope-orgmode.lib.config')

return {
  setup = config.setup,
  refile_heading = adapter.refile_heading,
  search_headings = adapter.search_headings,
  insert_link = adapter.insert_link,
  search_tags = require('telescope-orgmode.picker.search_tags').search_tags,
}
