local OrgFile = require('orgmode.files.file')
local org = require('telescope-orgmode.org')

-- Use [Section Name] format in describe() for grouped test output
-- See scripts/test-formatter.sh for formatting behavior
describe('[Data: Headline Loading]', function()
  ---@return OrgFile
  local load_file_sync = function(content, filename)
    content = content or {}
    filename = filename or vim.fn.tempname() .. '.org'
    vim.fn.writefile(content, filename)
    return OrgFile.load(filename):wait()
  end

  describe('basic loading', function()
    it('returns headlines from multiple files', function()
      -- Create test files
      local file1 = load_file_sync({ '* File1 Headline' })
      local file2 = load_file_sync({ '* File2 Headline' })

      -- Mock orgmode.files:all() to return our test files
      local original_require = require
      package.loaded['orgmode'] = {
        files = {
          all = function()
            return { file1, file2 }
          end,
        },
      }

      local headlines = org.load_headlines({})

      -- Restore original require
      require = original_require

      assert.are.same(2, #headlines)
      assert.are.same('File1 Headline', headlines[1].title)
      assert.are.same('File2 Headline', headlines[2].title)
    end)
  end)

  describe('archive filtering', function()
    it('respects archive filtering across files', function()
      local regular_file = load_file_sync({ '* Regular Headline' })
      local archive_filename = vim.fn.tempname() .. '.org_archive'
      local archive_file = load_file_sync({ '* Archive Headline' }, archive_filename)

      -- Mock orgmode.files:all()
      local original_require = require
      package.loaded['orgmode'] = {
        files = {
          all = function()
            return { regular_file, archive_file }
          end,
        },
      }

      local headlines_no_archive = org.load_headlines({})
      local headlines_with_archive = org.load_headlines({ archived = true })

      -- Restore
      require = original_require

      assert.are.same(1, #headlines_no_archive) -- only regular file
      assert.are.same(2, #headlines_with_archive) -- both files
    end)
  end)

  describe('todo and priority extraction', function()
    it('extracts todo_value, todo_type, and priority from headlines', function()
      local file = load_file_sync({
        '* TODO [#A] High priority task',
        '* DONE [#B] Completed task',
        '* PROGRESS Regular task',
        '* [#C] Note without TODO',
        '* Regular headline',
      })

      package.loaded['orgmode'] = {
        files = {
          all = function()
            return { file }
          end,
        },
      }

      local headlines = org.load_headlines({})

      -- First headline: TODO with priority A
      assert.are.same('TODO', headlines[1].todo_value)
      assert.are.same('TODO', headlines[1].todo_type)
      assert.are.same('A', headlines[1].priority)

      -- Second headline: DONE with priority B
      assert.are.same('DONE', headlines[2].todo_value)
      assert.are.same('DONE', headlines[2].todo_type)
      assert.are.same('B', headlines[2].priority)

      -- Third headline: PROGRESS without priority
      assert.are.same('PROGRESS', headlines[3].todo_value)
      assert.are.same('TODO', headlines[3].todo_type)

      -- Fourth headline: priority C without TODO
      assert.are.same('C', headlines[4].priority)

      -- Fifth headline: no TODO or priority
      assert.is_nil(headlines[5].todo_value)
      assert.is_nil(headlines[5].priority)
    end)
  end)

  describe('search-based loading', function()
    it('extracts TODO and priority from search results', function()
      local file = load_file_sync({
        '* TODO [#A] Important task :work:',
        '* DONE [#B] Completed task :work:',
        '* Regular task :personal:',
      })

      package.loaded['orgmode'] = {
        files = {
          all = function()
            return { file }
          end,
        },
      }

      local headlines = org.load_headlines_by_search('+work', {})

      -- Should only return work-tagged headlines
      assert.are.same(2, #headlines)

      -- Verify TODO and priority data preserved in search results
      assert.are.same('TODO', headlines[1].todo_value)
      assert.are.same('A', headlines[1].priority)
      assert.are.same('DONE', headlines[2].todo_value)
      assert.are.same('B', headlines[2].priority)
    end)
  end)

  describe('max_depth filtering', function()
    it('filters headlines by max_depth option', function()
      local file = load_file_sync({
        '* Level 1',
        '** Level 2',
        '*** Level 3',
        '* Another Level 1',
      })

      package.loaded['orgmode'] = {
        files = {
          all = function()
            return { file }
          end,
        },
      }

      local all_headlines = org.load_headlines({})
      local max_depth_1 = org.load_headlines({ max_depth = 1 })
      local max_depth_2 = org.load_headlines({ max_depth = 2 })

      assert.are.same(4, #all_headlines)
      assert.are.same(2, #max_depth_1) -- Only level 1 headlines
      assert.are.same(3, #max_depth_2) -- Level 1 and 2 headlines
    end)
  end)

  describe('current file filtering', function()
    it('filters headlines to current file only', function()
      local file1 = load_file_sync({ '* File1 Headline' })
      local file2 = load_file_sync({ '* File2 Headline' })

      package.loaded['orgmode'] = {
        files = {
          all = function()
            return { file1, file2 }
          end,
        },
      }

      local all_headlines = org.load_headlines({})
      local current_file_only = org.load_headlines({
        only_current_file = true,
        original_file = file1.filename,
      })

      assert.are.same(2, #all_headlines)
      assert.are.same(1, #current_file_only)
      assert.are.same('File1 Headline', current_file_only[1].title)
    end)
  end)
end)
