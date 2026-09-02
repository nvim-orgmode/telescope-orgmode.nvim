-- Golden-snapshot tests for the default source against committed
-- fixtures in spec/fixtures/sources/. Filenames are basename-
-- stripped so snapshots are CWD-independent.

local OrgFile = require('orgmode.files.file')
local snapshot = require('spec.helpers.snapshot')

local FIXTURE_DIR = 'spec/fixtures/sources'

local function load_fixture(name)
  return OrgFile.load(FIXTURE_DIR .. '/' .. name):wait()
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

local function basename(path)
  return vim.fn.fnamemodify(path, ':t')
end

local function strip_filenames(entries)
  for _, e in ipairs(entries) do
    if e.filename then
      e.filename = basename(e.filename)
    end
    if e.files then
      local mapped = {}
      for i, f in ipairs(e.files) do
        mapped[i] = basename(f)
      end
      table.sort(mapped)
      e.files = mapped
    end
  end
  return entries
end

local function sort_files_by_name(entries)
  table.sort(entries, function(a, b)
    return a.filename < b.filename
  end)
  return entries
end

local function sort_headlines(entries)
  table.sort(entries, function(a, b)
    if a.filename ~= b.filename then
      return a.filename < b.filename
    end
    return (a.line_number or 0) < (b.line_number or 0)
  end)
  return entries
end

local function sort_tags(entries)
  table.sort(entries, function(a, b)
    return a.tag < b.tag
  end)
  return entries
end

describe('[Unit: lib/sources/default golden-snapshot via fixtures]', function()
  local default, org
  local notes, project_a, archive

  before_each(function()
    package.loaded['telescope-orgmode.lib.sources.default'] = nil
    package.loaded['telescope-orgmode.org'] = nil
    default = require('telescope-orgmode.lib.sources.default')
    org = require('telescope-orgmode.org')
    require('telescope-orgmode.lib.sources').invalidate_cache()
    notes = load_fixture('notes.org')
    project_a = load_fixture('project_a.org')
    archive = load_fixture('legacy.org_archive')
    mock_orgmode({ notes, project_a, archive })
  end)

  -- Archive exclusion and depth capping are policy, so they are asserted
  -- against the loaders in org.lua. The source-level snapshots below
  -- cover the projection only.
  describe('load_files', function()
    it('returns non-archive files only by default', function()
      local out = sort_files_by_name(strip_filenames(snapshot.project_list(org.load_files({}), snapshot.project_file)))
      assert.same({
        { filename = 'notes.org', title = 'Notes' },
        { filename = 'project_a.org', title = 'Project A' },
      }, out)
    end)

    it('includes archive files when opts.archived', function()
      local out = sort_files_by_name(
        strip_filenames(snapshot.project_list(org.load_files({ archived = true }), snapshot.project_file))
      )
      assert.same({
        { filename = 'legacy.org_archive', title = 'Legacy Archive' },
        { filename = 'notes.org', title = 'Notes' },
        { filename = 'project_a.org', title = 'Project A' },
      }, out)
    end)
  end)

  describe('load_headlines', function()
    it('projects full schema, excludes archived headlines and archive files', function()
      local out =
        sort_headlines(strip_filenames(snapshot.project_list(org.load_headlines({}), snapshot.project_headline)))
      assert.same({
        {
          filename = 'notes.org',
          line_number = 3,
          title = 'Quick note',
          level = 1,
          todo_value = nil,
          todo_type = '',
          priority = nil,
          all_tags = { 'note' },
          is_archived = false,
          properties = {},
        },
        {
          filename = 'notes.org',
          line_number = 13,
          title = 'Reading list',
          level = 1,
          todo_value = nil,
          todo_type = '',
          priority = nil,
          all_tags = { 'reading' },
          is_archived = false,
          properties = {},
        },
        {
          filename = 'project_a.org',
          line_number = 3,
          title = 'Set up CI pipeline',
          level = 1,
          todo_value = 'TODO',
          todo_type = 'TODO',
          priority = nil,
          all_tags = { 'work', 'urgent' },
          is_archived = false,
          properties = {},
        },
        {
          filename = 'project_a.org',
          line_number = 11,
          title = 'Document architecture',
          level = 1,
          todo_value = 'DONE',
          todo_type = 'DONE',
          priority = nil,
          all_tags = { 'work' },
          is_archived = false,
          properties = {},
        },
        {
          filename = 'project_a.org',
          line_number = 19,
          title = 'Section under done task',
          level = 2,
          todo_value = nil,
          todo_type = '',
          priority = nil,
          all_tags = { 'work' },
          is_archived = false,
          properties = {},
        },
        {
          filename = 'project_a.org',
          line_number = 21,
          title = 'Plain headline without keyword',
          level = 1,
          todo_value = nil,
          todo_type = '',
          priority = nil,
          all_tags = { 'work' },
          is_archived = false,
          properties = {},
        },
        {
          filename = 'project_a.org',
          line_number = 27,
          title = 'Another plain headline',
          level = 1,
          todo_value = nil,
          todo_type = '',
          priority = nil,
          all_tags = { 'urgent' },
          is_archived = false,
          properties = {},
        },
      }, out)
    end)

    it('respects max_depth = 1 (drops level-2 sub-headline)', function()
      local out = sort_headlines(
        strip_filenames(snapshot.project_list(org.load_headlines({ max_depth = 1 }), snapshot.project_headline))
      )
      local titles = {}
      for _, e in ipairs(out) do
        titles[#titles + 1] = e.title
      end
      assert.same({
        'Quick note',
        'Reading list',
        'Set up CI pipeline',
        'Document architecture',
        'Plain headline without keyword',
        'Another plain headline',
      }, titles)
    end)

    it('show_properties extracts ID/CATEGORY for project_a headlines', function()
      local opts = { show_properties = { { name = 'ID' }, { name = 'CATEGORY' } } }
      local out = sort_headlines(
        strip_filenames(snapshot.project_list(default.enumerate_headlines(opts), snapshot.project_headline))
      )
      local props_by_title = {}
      for _, e in ipairs(out) do
        props_by_title[e.title] = e.properties
      end
      assert.same({ ID = 'project-a-task-1', CATEGORY = 'infra' }, props_by_title['Set up CI pipeline'])
      assert.same({ ID = 'project-a-task-2', CATEGORY = 'docs' }, props_by_title['Document architecture'])
      assert.same({ ID = 'project-a-task-3', CATEGORY = 'misc' }, props_by_title['Plain headline without keyword'])
    end)
  end)

  describe('enumerate_headlines_by_query', function()
    it('+work returns only work-tagged headlines', function()
      local out = sort_headlines(
        strip_filenames(
          snapshot.project_list(default.enumerate_headlines_by_query('+work', {}), snapshot.project_headline)
        )
      )
      local titles = {}
      for _, e in ipairs(out) do
        titles[#titles + 1] = e.title
      end
      assert.same({
        'Set up CI pipeline',
        'Document architecture',
        'Section under done task',
        'Plain headline without keyword',
      }, titles)
    end)

    it('+urgent returns urgent-tagged headlines', function()
      local out = sort_headlines(
        strip_filenames(
          snapshot.project_list(default.enumerate_headlines_by_query('+urgent', {}), snapshot.project_headline)
        )
      )
      local titles = {}
      for _, e in ipairs(out) do
        titles[#titles + 1] = e.title
      end
      assert.same({ 'Set up CI pipeline', 'Another plain headline' }, titles)
    end)
  end)

  describe('enumerate_tags', function()
    it('returns tag counts and files (archive file excluded; archived headlines kept by design)', function()
      -- enumerate_tags filters at file level (is_archive_file), not at
      -- headline level, so the :ARCHIVE: tag from notes.org is counted.
      -- That is intended.
      local out = sort_tags(strip_filenames(snapshot.project_list(default.enumerate_tags({}), snapshot.project_tag)))
      assert.same({
        { tag = 'ARCHIVE', count = 1, files = { 'notes.org' } },
        { tag = 'note', count = 1, files = { 'notes.org' } },
        { tag = 'reading', count = 1, files = { 'notes.org' } },
        { tag = 'urgent', count = 2, files = { 'project_a.org' } },
        { tag = 'work', count = 4, files = { 'project_a.org' } },
      }, out)
    end)
  end)
end)
