-- collect_tags_with_counts() and collect_tags_with_counts({ source =
-- 'default' }) must return identical results — both paths are routed
-- through the resolved source.

local OrgFile = require('orgmode.files.file')
local snapshot = require('spec.helpers.snapshot')

local function load_file_sync(content, filename)
  content = content or {}
  filename = filename or vim.fn.tempname() .. '.org'
  vim.fn.writefile(content, filename)
  return OrgFile.load(filename):wait()
end

local function mock_orgmode(files)
  package.loaded['orgmode'] = {
    files = {
      all = function()
        return files
      end,
    },
  }
end

local function normalize(entries)
  local list = snapshot.project_list(entries, snapshot.project_tag)
  for _, e in ipairs(list) do
    table.sort(e.files)
  end
  table.sort(list, function(a, b)
    return a.tag < b.tag
  end)
  return list
end

describe('[Unit: tag_collection.collect_tags_with_counts]', function()
  local tag_collection

  before_each(function()
    package.loaded['telescope-orgmode.tag_collection'] = nil
    package.loaded['telescope-orgmode.lib.sources'] = nil
    package.loaded['telescope-orgmode.lib.sources.default'] = nil
    package.loaded['telescope-orgmode.lib.config'] = nil
    package.loaded['telescope-orgmode.org'] = nil
    tag_collection = require('telescope-orgmode.tag_collection')
  end)

  it('opts=nil resolves to default source (delegated)', function()
    local f1 = load_file_sync({ '* A :work:urgent:', '* B :work:' })
    local f2 = load_file_sync({ '* C :reading:' })
    mock_orgmode({ f1, f2 })

    local without_opts = normalize(tag_collection.collect_tags_with_counts())
    local with_default = normalize(tag_collection.collect_tags_with_counts({ source = 'default' }))

    assert.same(with_default, without_opts)
  end)

  it('opts={} resolves identically to opts=nil', function()
    local f1 = load_file_sync({ '* A :alpha:', '* B :beta:alpha:' })
    mock_orgmode({ f1 })

    local empty = normalize(tag_collection.collect_tags_with_counts({}))
    local nilarg = normalize(tag_collection.collect_tags_with_counts())

    assert.same(nilarg, empty)
  end)

  -- Anti-regression: pins the expected tag counts for a known fixture
  -- set. Catches silent drift in tag-collection counts.
  it('returns expected baseline counts for known fixture content', function()
    local f1 = load_file_sync({
      '* TODO Task one :work:urgent:',
      '* DONE Task two :work:',
      '** Sub of two',
      '* Plain :work:',
    })
    local f2 = load_file_sync({ '* Reading :reading:' })
    mock_orgmode({ f1, f2 })

    local out = normalize(tag_collection.collect_tags_with_counts())
    local count_by_tag = {}
    for _, e in ipairs(out) do
      count_by_tag[e.tag] = e.count
    end

    -- Expected counts (with tag inheritance for 'Sub of two':work:):
    --   work    = 4 (TODO, DONE, Sub-inherited, Plain)
    --   urgent  = 1 (TODO)
    --   reading = 1 (Reading)
    assert.equals(4, count_by_tag.work)
    assert.equals(1, count_by_tag.urgent)
    assert.equals(1, count_by_tag.reading)
  end)
end)
