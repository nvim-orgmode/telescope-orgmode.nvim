-- TODO: include headline.level and headline.is_archived() as part of the
-- public orgmode api

return require('telescope').register_extension({
  setup = require('telescope-orgmode').setup,
  exports = {
    search_headings = require('telescope-orgmode').search_headings,
    refile_heading = require('telescope-orgmode').refile_heading,
    insert_link = require('telescope-orgmode').insert_link,
    search_tags = require('telescope-orgmode').search_tags,
  },
})
