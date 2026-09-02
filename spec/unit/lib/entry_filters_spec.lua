-- Unit tests for lib/entry_filters.lua. Pure table logic: no orgmode,
-- no picker. Only sort_by_file_mtime touches the filesystem.

local filters = require('telescope-orgmode.lib.entry_filters')

local function write_file(mtime, suffix)
  local filename = vim.fn.tempname() .. (suffix or '.org')
  vim.fn.writefile({ '* H' }, filename)
  if mtime then
    vim.uv.fs_utime(filename, mtime, mtime)
  end
  return filename
end

describe('[Unit: lib/entry_filters]', function()
  describe('only_current_file', function()
    it('keeps only entries from original_file', function()
      local entries = { { filename = '/a.org' }, { filename = '/b.org' } }

      local result = filters.only_current_file(entries, {
        only_current_file = true,
        original_file = '/a.org',
      })

      assert.equals(1, #result)
      assert.equals('/a.org', result[1].filename)
    end)

    it('passes everything through when the flag is off', function()
      local entries = { { filename = '/a.org' }, { filename = '/b.org' } }

      assert.equals(2, #filters.only_current_file(entries, {}))
    end)
  end)

  describe('exclude_archive_files', function()
    it('drops .org_archive entries', function()
      local entries = { { filename = '/a.org' }, { filename = '/b.org_archive' } }

      local result = filters.exclude_archive_files(entries, {})

      assert.equals(1, #result)
      assert.equals('/a.org', result[1].filename)
    end)

    it('keeps them when archived=true', function()
      local entries = { { filename = '/a.org' }, { filename = '/b.org_archive' } }

      assert.equals(2, #filters.exclude_archive_files(entries, { archived = true }))
    end)
  end)

  describe('exclude_archived_subtrees', function()
    it('drops entries flagged is_archived', function()
      local entries = {
        { filename = '/a.org', is_archived = false },
        { filename = '/a.org', is_archived = true },
      }

      local result = filters.exclude_archived_subtrees(entries, {})

      assert.equals(1, #result)
      assert.is_false(result[1].is_archived)
    end)

    it('keeps them when archived=true', function()
      local entries = {
        { filename = '/a.org', is_archived = false },
        { filename = '/a.org', is_archived = true },
      }

      assert.equals(2, #filters.exclude_archived_subtrees(entries, { archived = true }))
    end)
  end)

  describe('max_depth', function()
    it('caps headline level', function()
      local entries = { { level = 1 }, { level = 2 }, { level = 3 } }

      assert.equals(2, #filters.max_depth(entries, { max_depth = 2 }))
    end)

    it('passes everything through when unset', function()
      local entries = { { level = 1 }, { level = 3 } }

      assert.equals(2, #filters.max_depth(entries, {}))
    end)
  end)

  describe('sort_by_file_mtime', function()
    it('orders newest file first', function()
      local older = write_file(1000)
      local newer = write_file(2000)
      local entries = { { filename = older }, { filename = newer } }

      local result = filters.sort_by_file_mtime(entries)

      assert.equals(newer, result[1].filename)
      assert.equals(older, result[2].filename)
    end)

    it('preserves within-file order', function()
      local older = write_file(1000)
      local newer = write_file(2000)
      local entries = {
        { filename = older, title = 'old-1' },
        { filename = older, title = 'old-2' },
        { filename = newer, title = 'new-1' },
        { filename = newer, title = 'new-2' },
      }

      local result = filters.sort_by_file_mtime(entries)

      assert.same(
        { 'new-1', 'new-2', 'old-1', 'old-2' },
        vim.tbl_map(function(entry)
          return entry.title
        end, result)
      )
    end)
  end)
end)
