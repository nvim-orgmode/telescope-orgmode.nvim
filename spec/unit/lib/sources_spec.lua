-- Unit tests for lib/sources/init.lua
--
-- Phase 2 (tom-0044): Source-Skelett
--   * Registry-Lookup mit Type-Union (Pre-Built/Factory) + Cache
--   * Runtime-Validation auf unbekannte Sources
--   * Drei Normalisierungs-Funktionen (headline/file/tag)
--   * validate_setup() für referenzielle Integrität
--   * invalidate_cache() für Setup-Idempotenz
--
-- Test-Isolation: sources ist Modul-State (siehe Plan §Implementation Risks).
-- before_each ruft invalidate_cache() auf.

local sources = require('telescope-orgmode.lib.sources')

local function fake_source(name)
  return {
    name = name or 'fake',
    enumerate_files = function() end,
    enumerate_headlines = function() end,
    enumerate_tags = function() end,
  }
end

describe('[Unit: lib/sources]', function()
  before_each(function()
    sources.invalidate_cache()
  end)

  describe('resolve_source', function()
    it('resolves a pre-built source from registry', function()
      local default = fake_source('default')
      local config = {
        sources = { default = default },
        default_source = 'default',
        picker_defaults = {},
      }

      local source = sources.resolve_source({}, config)

      assert.equals('default', source.name)
    end)

    it('invokes a factory source and persists the result', function()
      local call_count = 0
      local config = {
        sources = {
          factory = function()
            call_count = call_count + 1
            return fake_source('factory')
          end,
        },
        default_source = 'factory',
        picker_defaults = {},
      }

      local first = sources.resolve_source({}, config)
      local second = sources.resolve_source({}, config)

      assert.equals('factory', first.name)
      assert.equals('factory', second.name)
      assert.equals(1, call_count)
    end)

    it('prefers opts.source over picker/default source', function()
      local config = {
        sources = {
          default = fake_source('default'),
          custom = fake_source('custom'),
        },
        default_source = 'default',
        picker_defaults = {},
      }

      local source = sources.resolve_source({ source = 'custom' }, config)

      assert.equals('custom', source.name)
    end)

    it('falls back to picker_defaults[picker_type].source', function()
      local config = {
        sources = {
          default = fake_source('default'),
          picker_specific = fake_source('picker_specific'),
        },
        default_source = 'default',
        picker_defaults = {
          insert_link = { source = 'picker_specific' },
        },
      }

      local source = sources.resolve_source({ picker_type = 'insert_link' }, config)

      assert.equals('picker_specific', source.name)
    end)

    it('throws a clear error when opts.source is unknown', function()
      local config = {
        sources = { default = fake_source('default') },
        default_source = 'default',
        picker_defaults = {},
      }

      assert.has_error(function()
        sources.resolve_source({ source = 'roam_db' }, config)
      end, 'Unknown source: roam_db')
    end)
  end)

  describe('normalize_headline', function()
    it('leaves a fully-populated entry unchanged', function()
      local entry = {
        filename = '/tmp/a.org',
        line_number = 5,
        title = 'Task',
        level = 1,
        all_tags = { 'work' },
        is_archived = false,
        todo_value = 'TODO',
        todo_type = 'TODO',
        priority = 'A',
        properties = { ID = 'x' },
      }

      local result = sources.normalize_headline(entry)

      assert.equals(entry, result) -- in-place
      assert.equals('TODO', result.todo_value)
      assert.equals('A', result.priority)
      assert.same({ 'work' }, result.all_tags)
      assert.same({ ID = 'x' }, result.properties)
    end)

    it('fills missing optional fields with defaults', function()
      local entry = {
        filename = '/tmp/a.org',
        line_number = 5,
        title = 'Task',
        level = 1,
      }

      sources.normalize_headline(entry)

      assert.same({}, entry.all_tags)
      assert.is_false(entry.is_archived)
      assert.is_nil(entry.todo_value)
      assert.equals('', entry.todo_type)
      assert.is_nil(entry.priority)
      assert.same({}, entry.properties)
    end)
  end)

  describe('normalize_file', function()
    it('leaves a fully-populated entry unchanged', function()
      local entry = { filename = '/tmp/notes.org', title = 'My Notes' }

      sources.normalize_file(entry)

      assert.equals('My Notes', entry.title)
    end)

    it('derives title from filename when missing', function()
      local entry = { filename = '/tmp/notes.org' }

      sources.normalize_file(entry)

      assert.equals('notes', entry.title)
    end)
  end)

  describe('normalize_tag', function()
    it('leaves a fully-populated entry unchanged', function()
      local entry = { tag = 'work', count = 7, files = { '/a.org' } }

      sources.normalize_tag(entry)

      assert.equals(7, entry.count)
      assert.same({ '/a.org' }, entry.files)
    end)

    it('fills missing optional fields with defaults', function()
      local entry = { tag = 'work' }

      sources.normalize_tag(entry)

      assert.equals(1, entry.count)
      assert.same({}, entry.files)
    end)
  end)

  describe('validate_setup', function()
    it('returns ok when all source references are registered', function()
      local config = {
        sources = {
          default = fake_source('default'),
          custom = fake_source('custom'),
        },
        default_source = 'default',
        picker_defaults = {
          insert_link = { source = 'custom' },
          search_headings = { source = nil },
        },
      }

      local ok, err = sources.validate_setup(config)

      assert.is_true(ok)
      assert.is_nil(err)
    end)

    it('rejects unknown default_source with a clear message', function()
      local config = {
        sources = { default = fake_source('default') },
        default_source = 'nonexistent',
        picker_defaults = {},
      }

      local ok, err = sources.validate_setup(config)

      assert.is_false(ok)
      assert.is_string(err)
      assert.is_truthy(err:find('default_source'))
      assert.is_truthy(err:find('nonexistent'))
    end)

    it('rejects unknown picker_defaults[*].source with location info', function()
      local config = {
        sources = { default = fake_source('default') },
        default_source = 'default',
        picker_defaults = {
          insert_link = { source = 'nope' },
        },
      }

      local ok, err = sources.validate_setup(config)

      assert.is_false(ok)
      assert.is_string(err)
      assert.is_truthy(err:find('picker_defaults.insert_link.source'))
      assert.is_truthy(err:find('nope'))
    end)
  end)

  describe('invalidate_cache', function()
    it('forces re-execution of factory sources', function()
      local call_count = 0
      local config = {
        sources = {
          factory = function()
            call_count = call_count + 1
            return fake_source('factory')
          end,
        },
        default_source = 'factory',
        picker_defaults = {},
      }

      sources.resolve_source({}, config)
      sources.invalidate_cache()
      sources.resolve_source({}, config)

      assert.equals(2, call_count)
    end)
  end)
end)
