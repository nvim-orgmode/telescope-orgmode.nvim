-- TODO: include headline.level and headline.is_archived() as part of the
-- public orgmode api
-- TODO: add highlight groups

return require('telescope').register_extension({
  exports = {
    search_headings = require('telescope._extensions.orgmode.search_headings'),
    refile_heading = require('telescope._extensions.orgmode.refile_heading'),
  },
})
