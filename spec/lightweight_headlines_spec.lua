local OrgFile = require('orgmode.files.file')
local org = require('telescope-orgmode.org')

describe('Telescope Orgmode Integration', function()
  ---@return OrgFile
  local load_file_sync = function(content, filename)
    content = content or {}
    filename = filename or vim.fn.tempname() .. '.org'
    vim.fn.writefile(content, filename)
    return OrgFile.load(filename):wait()
  end

  describe('org.load_headlines integration', function()
    it('should return headlines from multiple files', function()
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

    it('should respect archive filtering across files', function()
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
end)
