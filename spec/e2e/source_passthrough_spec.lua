-- Verifies that each picker data path returns identical results when
-- opts.source is omitted vs explicitly set to 'default'. Comparison is
-- done on projected fields (spec/helpers/snapshot.lua) to avoid spurious
-- diffs from orgmode-API closures / TS refs.

local e2e_helpers = require('spec.helpers.e2e_helpers')
local snapshot = require('spec.helpers.snapshot')

describe('[E2E: Source Passthrough]', function()
  local headlines_entry
  local orgfiles_entry
  local tags_lib

  before_each(function()
    -- Module reset: clear the source and notify caches so every test
    -- starts from the same state.
    package.loaded['telescope-orgmode.lib.sources'] = nil
    package.loaded['telescope-orgmode.lib.sources.default'] = nil
    package.loaded['telescope-orgmode.org'] = nil
    package.loaded['telescope-orgmode.lib.config'] = nil
    package.loaded['telescope-orgmode.tag_collection'] = nil
    package.loaded['telescope-orgmode.lib.tags'] = nil
    package.loaded['telescope-orgmode.entry_maker.headlines'] = nil
    package.loaded['telescope-orgmode.entry_maker.orgfiles'] = nil

    require('telescope-orgmode.lib.config').setup({})

    headlines_entry = require('telescope-orgmode.entry_maker.headlines')
    orgfiles_entry = require('telescope-orgmode.entry_maker.orgfiles')
    tags_lib = require('telescope-orgmode.lib.tags')

    e2e_helpers.create_test_org_files()
    e2e_helpers.setup_orgmode_with_test_files()
  end)

  after_each(function()
    e2e_helpers.cleanup_test_org_files()
  end)

  --- Project headlines list (entry_maker output → underlying headline data).
  ---@param entries table[] entry_maker output ({ filename, headline })
  ---@return table[]
  local function project_headlines(entries)
    local out = {}
    for i, entry in ipairs(entries) do
      out[i] = snapshot.project_headline(entry.headline)
    end
    return out
  end

  it('search_headings: passthrough opts.source = "default"', function()
    local opts_naked = {}
    local opts_default = { source = 'default' }

    local naked = headlines_entry.get_entries(opts_naked)
    local with_source = headlines_entry.get_entries(opts_default)

    assert.same(project_headlines(naked), project_headlines(with_source))
  end)

  it('refile_heading: passthrough opts.source = "default" (orgfiles mode)', function()
    -- refile_heading uses orgfiles_entry.get_entries in orgfiles mode.
    local naked = orgfiles_entry.get_entries({})
    local with_source = orgfiles_entry.get_entries({ source = 'default' })

    local function project(list)
      local out = {}
      for i, entry in ipairs(list) do
        out[i] = snapshot.project_file(entry)
      end
      return out
    end

    assert.same(project(naked), project(with_source))
  end)

  it('insert_link: passthrough opts.source = "default"', function()
    -- Shares the headline data path with search_headings; kept separate
    -- so drift in either path is isolated.
    local naked = headlines_entry.get_entries({})
    local with_source = headlines_entry.get_entries({ source = 'default' })

    assert.same(project_headlines(naked), project_headlines(with_source))
  end)

  it('search_tags: passthrough opts.source = "default"', function()
    local naked_tags = tags_lib.load_and_sort_tags({})
    local with_source_tags = tags_lib.load_and_sort_tags({ source = 'default' })

    -- files lists come from a set, so their order is not stable.
    local function normalize(list)
      local out = {}
      for i, entry in ipairs(list) do
        out[i] = snapshot.project_tag(entry)
        table.sort(out[i].files)
      end
      return out
    end

    assert.same(normalize(naked_tags), normalize(with_source_tags))
  end)
end)
