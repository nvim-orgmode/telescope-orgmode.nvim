local filters = require('telescope-orgmode.lib.filters')

describe('[Unit: lib/filters]', function()
  describe('get_open_buffers', function()
    it('should return list of org files from loaded buffers', function()
      -- Test will fail - function doesn't exist yet
      local result = filters.get_open_buffers()

      assert.is_table(result)
      assert.is_true(#result >= 0) -- Should be a list (empty or non-empty)
    end)

    it('should filter out non-org files', function()
      -- Expected behavior: only return .org files from open buffers
      local result = filters.get_open_buffers()

      for _, filepath in ipairs(result) do
        assert.is_string(filepath)
        -- Should end with .org
        assert.is_true(filepath:match('%.org$') ~= nil, 'Expected .org file, got: ' .. filepath)
      end
    end)

    it('should return paths in consistent format', function()
      -- Expected behavior: absolute paths, normalized
      local result = filters.get_open_buffers()

      for _, filepath in ipairs(result) do
        -- Should be absolute path (starts with /)
        assert.is_true(filepath:match('^/') ~= nil, 'Expected absolute path, got: ' .. filepath)
      end
    end)
  end)

  describe('apply_file_filter', function()
    local sample_headlines

    before_each(function()
      -- Sample headlines from different files
      sample_headlines = {
        { title = 'Headline 1', filename = '/path/to/todo.org', line = 1 },
        { title = 'Headline 2', filename = '/path/to/work.org', line = 5 },
        { title = 'Headline 3', filename = '/path/to/todo.org', line = 10 },
        { title = 'Headline 4', filename = '/path/to/notes.org', line = 3 },
      }
    end)

    it('should return all headlines when file_list is empty', function()
      -- Test will fail - function doesn't exist yet
      local result = filters.apply_file_filter(sample_headlines, {})

      assert.are.equal(4, #result)
      assert.are.same(sample_headlines, result)
    end)

    it('should filter headlines to single file', function()
      local result = filters.apply_file_filter(sample_headlines, { '/path/to/todo.org' })

      assert.are.equal(2, #result)
      assert.are.equal('Headline 1', result[1].title)
      assert.are.equal('Headline 3', result[2].title)

      -- All results should be from the filtered file
      for _, headline in ipairs(result) do
        assert.are.equal('/path/to/todo.org', headline.filename)
      end
    end)

    it('should filter headlines to multiple files', function()
      local result = filters.apply_file_filter(sample_headlines, {
        '/path/to/todo.org',
        '/path/to/notes.org',
      })

      assert.are.equal(3, #result)

      -- Should include headlines from both files
      local files_in_result = {}
      for _, headline in ipairs(result) do
        files_in_result[headline.filename] = true
      end

      assert.is_true(files_in_result['/path/to/todo.org'])
      assert.is_true(files_in_result['/path/to/notes.org'])
      assert.is_nil(files_in_result['/path/to/work.org'])
    end)

    it('should return empty result when no headlines match filter', function()
      local result = filters.apply_file_filter(sample_headlines, { '/path/to/nonexistent.org' })

      assert.are.equal(0, #result)
      assert.are.same({}, result)
    end)

    it('should handle empty headlines list', function()
      local result = filters.apply_file_filter({}, { '/path/to/todo.org' })

      assert.are.equal(0, #result)
      assert.are.same({}, result)
    end)

    it('should handle nil file_list as all files', function()
      -- nil should be treated as "no filter" (same as empty table)
      local result = filters.apply_file_filter(sample_headlines, nil)

      assert.are.equal(4, #result)
      assert.are.same(sample_headlines, result)
    end)
  end)

  describe('apply_file_list_filter', function()
    local sample_files

    before_each(function()
      sample_files = {
        { filename = '/path/to/todo.org', title = 'Todo File' },
        { filename = '/path/to/work.org', title = 'Work File' },
        { filename = '/path/to/notes.org', title = 'Notes File' },
      }
    end)

    it('should return all files when file_list is empty', function()
      -- Test will fail - function doesn't exist yet
      local result = filters.apply_file_list_filter(sample_files, {})

      assert.are.equal(3, #result)
      assert.are.same(sample_files, result)
    end)

    it('should filter to single file', function()
      local result = filters.apply_file_list_filter(sample_files, { '/path/to/work.org' })

      assert.are.equal(1, #result)
      assert.are.equal('Work File', result[1].title)
      assert.are.equal('/path/to/work.org', result[1].filename)
    end)

    it('should filter to multiple files', function()
      local result = filters.apply_file_list_filter(sample_files, {
        '/path/to/todo.org',
        '/path/to/notes.org',
      })

      assert.are.equal(2, #result)

      -- Should include both files
      local filenames_in_result = {}
      for _, file in ipairs(result) do
        filenames_in_result[file.filename] = true
      end

      assert.is_true(filenames_in_result['/path/to/todo.org'])
      assert.is_true(filenames_in_result['/path/to/notes.org'])
      assert.is_nil(filenames_in_result['/path/to/work.org'])
    end)

    it('should return empty result when no files match filter', function()
      local result = filters.apply_file_list_filter(sample_files, { '/path/to/nonexistent.org' })

      assert.are.equal(0, #result)
      assert.are.same({}, result)
    end)

    it('should handle empty files list', function()
      local result = filters.apply_file_list_filter({}, { '/path/to/todo.org' })

      assert.are.equal(0, #result)
      assert.are.same({}, result)
    end)

    it('should handle nil file_list as all files', function()
      -- nil should be treated as "no filter" (same as empty table)
      local result = filters.apply_file_list_filter(sample_files, nil)

      assert.are.equal(3, #result)
      assert.are.same(sample_files, result)
    end)
  end)
end)
