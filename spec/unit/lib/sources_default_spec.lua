-- Unit tests for lib/sources/default.lua. Uses the real OrgFile.load +
-- mocked `require('orgmode').files:all` pattern from
-- spec/integration/data/headline_loading_spec.lua.

local OrgFile = require('orgmode.files.file')

local function load_file_sync(content, filename)
  content = content or {}
  filename = filename or vim.fn.tempname() .. '.org'
  vim.fn.writefile(content, filename)
  return OrgFile.load(filename):wait()
end

local function load_archive_sync(content)
  return load_file_sync(content, vim.fn.tempname() .. '.org_archive')
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

describe('[Unit: lib/sources/default]', function()
  local default

  before_each(function()
    package.loaded['telescope-orgmode.lib.sources.default'] = nil
    default = require('telescope-orgmode.lib.sources.default')
  end)

  describe('enumerate_files', function()
    it('returns {filename, title} entries for every file', function()
      local f1 = load_file_sync({ '#+TITLE: First', '* H1' })
      local f2 = load_file_sync({ '#+TITLE: Second', '* H2' })
      mock_orgmode({ f1, f2 })

      local result = default.enumerate_files({})

      assert.equals(2, #result)
      local titles = { result[1].title, result[2].title }
      table.sort(titles)
      assert.same({ 'First', 'Second' }, titles)
    end)

    -- Provider contract: archive exclusion and only_current_file are
    -- policy, applied in org.lua via lib/entry_filters.lua.
    it('includes .org_archive files', function()
      local regular = load_file_sync({ '* Regular' })
      local archive = load_archive_sync({ '* Archived' })
      mock_orgmode({ regular, archive })

      local result = default.enumerate_files({})

      assert.equals(2, #result)
    end)

    it('ignores only_current_file', function()
      local f1 = load_file_sync({ '* A' })
      local f2 = load_file_sync({ '* B' })
      mock_orgmode({ f1, f2 })

      local result = default.enumerate_files({
        only_current_file = true,
        original_file = f1.filename,
      })

      assert.equals(2, #result)
    end)
  end)

  describe('enumerate_headlines', function()
    it('returns full headline schema', function()
      local file = load_file_sync({
        '* TODO [#A] Task one :work:',
        '* DONE Task two',
      })
      mock_orgmode({ file })

      local result = default.enumerate_headlines({})

      assert.equals(2, #result)
      assert.equals('Task one', result[1].title)
      assert.equals('TODO', result[1].todo_value)
      assert.equals('TODO', result[1].todo_type)
      assert.equals('A', result[1].priority)
      assert.same({ 'work' }, result[1].all_tags)
      assert.is_false(result[1].is_archived)
      assert.equals(1, result[1].level)
      assert.equals(1, result[1].line_number)
      assert.same({}, result[1].properties)

      assert.equals('DONE', result[2].todo_value)
      assert.equals('DONE', result[2].todo_type)
    end)

    it('ignores max_depth', function()
      local file = load_file_sync({
        '* L1',
        '** L2',
        '*** L3',
      })
      mock_orgmode({ file })

      local result = default.enumerate_headlines({ max_depth = 2 })

      assert.equals(3, #result)
    end)

    it('includes archived subtrees, flagged via is_archived', function()
      -- Headline-level :ARCHIVE: tag triggers is_archived().
      local file = load_file_sync({
        '* Active',
        '* Archived branch                                                :ARCHIVE:',
      })
      mock_orgmode({ file })

      local result = default.enumerate_headlines({})

      assert.equals(2, #result)
      assert.is_false(result[1].is_archived)
      assert.is_true(result[2].is_archived)
    end)

    it('loads properties when show_properties is set', function()
      local file = load_file_sync({
        '* Task',
        ':PROPERTIES:',
        ':ID: abc',
        ':END:',
      })
      mock_orgmode({ file })

      local result = default.enumerate_headlines({
        show_properties = { { name = 'ID' }, { name = 'EFFORT' } },
      })

      assert.equals('abc', result[1].properties.ID)
      assert.equals('', result[1].properties.EFFORT)
    end)
  end)

  describe('enumerate_headlines_by_query', function()
    it('filters by query', function()
      local file = load_file_sync({
        '* Task A :work:',
        '* Task B :personal:',
        '* Task C :work:',
      })
      mock_orgmode({ file })

      local result = default.enumerate_headlines_by_query('+work', {})

      assert.equals(2, #result)
      assert.equals('Task A', result[1].title)
      assert.equals('Task C', result[2].title)
    end)

    -- max_count is not a source concern: it existed only on the tag
    -- preview path, which caps the result itself.
    it('ignores max_count', function()
      local file = load_file_sync({
        '* H1 :work:',
        '* H2 :work:',
        '* H3 :work:',
      })
      mock_orgmode({ file })

      local result = default.enumerate_headlines_by_query('+work', { max_count = 2 })

      assert.equals(3, #result)
    end)

    -- The two exclusions below come from orgmode's own `apply_search`,
    -- not from this source. Main relied on the same behaviour.
    it('excludes archived subtrees by default', function()
      local file = load_file_sync({
        '* Active :work:',
        '* Done branch                                                :work:ARCHIVE:',
      })
      mock_orgmode({ file })

      local result = default.enumerate_headlines_by_query('+work', {})

      assert.equals(1, #result)
      assert.equals('Active', result[1].title)
    end)

    it('excludes .org_archive files', function()
      local regular = load_file_sync({ '* H1 :work:' })
      local archive = load_archive_sync({ '* H2 :work:' })
      mock_orgmode({ regular, archive })

      local result = default.enumerate_headlines_by_query('+work', {})

      assert.equals(1, #result)
      assert.equals('H1', result[1].title)
    end)
  end)

  describe('enumerate_tags', function()
    it('counts tag occurrences across files', function()
      local f1 = load_file_sync({ '* A :work:', '* B :work:urgent:' })
      local f2 = load_file_sync({ '* C :work:' })
      mock_orgmode({ f1, f2 })

      local result = default.enumerate_tags({})

      local by_tag = {}
      for _, t in ipairs(result) do
        by_tag[t.tag] = t
      end

      assert.equals(3, by_tag.work.count)
      assert.equals(1, by_tag.urgent.count)
      assert.equals(2, #by_tag.work.files)
    end)

    it('excludes .org_archive files', function()
      local regular = load_file_sync({ '* A :work:' })
      local archive = load_archive_sync({ '* B :legacy:' })
      mock_orgmode({ regular, archive })

      local result = default.enumerate_tags({})

      local by_tag = {}
      for _, t in ipairs(result) do
        by_tag[t.tag] = t
      end

      assert.is_not_nil(by_tag.work)
      assert.is_nil(by_tag.legacy)
    end)
  end)
end)
