---@diagnostic disable: undefined-field
local entry_normalize = require('telescope-orgmode.lib.entry_normalize')

describe('[Unit: lib/entry_normalize]', function()
  describe('normalize_telescope_entry', function()
    it('should extract value wrapper from Telescope entry', function()
      local telescope_entry = {
        value = {
          filename = '/path/to/file.org',
          headline = { line_number = 10, title = 'Test Headline' },
        },
        display = 'Test Display',
        ordinal = 'Test Ordinal',
      }

      local normalized = entry_normalize.normalize_telescope_entry(telescope_entry)

      assert.equals('/path/to/file.org', normalized.filename)
      assert.equals(10, normalized.headline.line_number)
      assert.equals('Test Headline', normalized.headline.title)
    end)

    it('should return entry as-is if no value wrapper', function()
      local direct_entry = {
        filename = '/path/to/file.org',
        headline = { line_number = 10 },
      }

      local normalized = entry_normalize.normalize_telescope_entry(direct_entry)

      assert.equals(direct_entry, normalized)
    end)
  end)

  describe('normalize_snacks_entry', function()
    it('should extract __entry wrapper from Snacks entry', function()
      local snacks_entry = {
        __entry = {
          filename = '/path/to/file.org',
          headline = { line_number = 20, title = 'Snacks Headline' },
        },
        file = '/path/to/file.org',
        text = 'Display text',
        preview = 'file',
      }

      local normalized = entry_normalize.normalize_snacks_entry(snacks_entry)

      assert.equals('/path/to/file.org', normalized.filename)
      assert.equals(20, normalized.headline.line_number)
      assert.equals('Snacks Headline', normalized.headline.title)
    end)

    it('should return entry as-is if no __entry wrapper', function()
      local direct_entry = {
        filename = '/path/to/file.org',
        headline = { line_number = 20 },
      }

      local normalized = entry_normalize.normalize_snacks_entry(direct_entry)

      assert.equals(direct_entry, normalized)
    end)
  end)

  describe('normalize_fzf_entry', function()
    it('should extract data wrapper from fzf-lua entry', function()
      local fzf_entry = {
        data = {
          filename = '/path/to/file.org',
          headline = { line_number = 30, title = 'FZF Headline' },
        },
      }

      local normalized = entry_normalize.normalize_fzf_entry(fzf_entry)

      assert.equals('/path/to/file.org', normalized.filename)
      assert.equals(30, normalized.headline.line_number)
    end)

    it('should return entry as-is if no data wrapper', function()
      local direct_entry = {
        filename = '/path/to/file.org',
        headline = { line_number = 30 },
      }

      local normalized = entry_normalize.normalize_fzf_entry(direct_entry)

      assert.equals(direct_entry, normalized)
    end)
  end)

  describe('normalize_entry (auto-detection)', function()
    it('should handle Telescope entry with value wrapper', function()
      local telescope_entry = {
        value = {
          filename = '/path/to/file.org',
          headline = { line_number = 10 },
        },
      }

      local normalized = entry_normalize.normalize_entry(telescope_entry)

      assert.equals('/path/to/file.org', normalized.filename)
      assert.equals(10, normalized.headline.line_number)
    end)

    it('should handle Snacks entry with __entry wrapper', function()
      local snacks_entry = {
        __entry = {
          filename = '/path/to/file.org',
          headline = { line_number = 20 },
        },
        file = '/path/to/file.org',
      }

      local normalized = entry_normalize.normalize_entry(snacks_entry)

      assert.equals('/path/to/file.org', normalized.filename)
      assert.equals(20, normalized.headline.line_number)
    end)

    it('should handle fzf-lua entry with data wrapper', function()
      local fzf_entry = {
        data = {
          filename = '/path/to/file.org',
          headline = { line_number = 30 },
        },
      }

      local normalized = entry_normalize.normalize_entry(fzf_entry)

      assert.equals('/path/to/file.org', normalized.filename)
      assert.equals(30, normalized.headline.line_number)
    end)

    it('should handle direct entry format', function()
      local direct_entry = {
        filename = '/path/to/file.org',
        headline = { line_number = 40 },
      }

      local normalized = entry_normalize.normalize_entry(direct_entry)

      assert.equals('/path/to/file.org', normalized.filename)
      assert.equals(40, normalized.headline.line_number)
    end)

    it('should prioritize value over __entry when both present', function()
      local mixed_entry = {
        value = {
          filename = '/value/path.org',
          headline = { line_number = 10 },
        },
        __entry = {
          filename = '/entry/path.org',
          headline = { line_number = 20 },
        },
      }

      local normalized = entry_normalize.normalize_entry(mixed_entry)

      assert.equals('/value/path.org', normalized.filename)
      assert.equals(10, normalized.headline.line_number)
    end)
  end)

  describe('get_filename', function()
    it('should extract filename from Telescope entry', function()
      local entry = {
        value = { filename = '/telescope/path.org' },
      }

      assert.equals('/telescope/path.org', entry_normalize.get_filename(entry))
    end)

    it('should extract filename from Snacks entry', function()
      local entry = {
        __entry = { filename = '/snacks/path.org' },
      }

      assert.equals('/snacks/path.org', entry_normalize.get_filename(entry))
    end)

    it('should extract filename from direct entry', function()
      local entry = { filename = '/direct/path.org' }

      assert.equals('/direct/path.org', entry_normalize.get_filename(entry))
    end)

    it('should handle file field as fallback', function()
      local entry = { file = '/fallback/path.org' }

      assert.equals('/fallback/path.org', entry_normalize.get_filename(entry))
    end)
  end)

  describe('get_headline', function()
    it('should extract headline from Telescope entry', function()
      local headline_data = { line_number = 10, title = 'Test' }
      local entry = {
        value = {
          filename = '/path.org',
          headline = headline_data,
        },
      }

      local result = entry_normalize.get_headline(entry)

      assert.equals(headline_data, result)
    end)

    it('should extract headline from Snacks entry', function()
      local headline_data = { line_number = 20, title = 'Snacks' }
      local entry = {
        __entry = {
          filename = '/path.org',
          headline = headline_data,
        },
      }

      local result = entry_normalize.get_headline(entry)

      assert.equals(headline_data, result)
    end)

    it('should return nil for orgfile entry', function()
      local entry = {
        value = { filename = '/path.org' },
      }

      local result = entry_normalize.get_headline(entry)

      assert.is_nil(result)
    end)
  end)

  describe('is_headline_entry', function()
    it('should return true for headline entry', function()
      local entry = {
        value = {
          filename = '/path.org',
          headline = { line_number = 10 },
        },
      }

      assert.is_true(entry_normalize.is_headline_entry(entry))
    end)

    it('should return false for orgfile entry', function()
      local entry = {
        value = { filename = '/path.org' },
      }

      assert.is_false(entry_normalize.is_headline_entry(entry))
    end)

    it('should handle direct format', function()
      local headline_entry = {
        filename = '/path.org',
        headline = { line_number = 10 },
      }
      local file_entry = { filename = '/path.org' }

      assert.is_true(entry_normalize.is_headline_entry(headline_entry))
      assert.is_false(entry_normalize.is_headline_entry(file_entry))
    end)
  end)
end)
