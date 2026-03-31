--- Integration Tests: Snacks without Telescope installed
--- Verifies that the Snacks adapter works when telescope.nvim is not available
--- Regression test for GitHub issue #40

local has_snacks = pcall(require, 'snacks')
if not has_snacks then
  return
end

local helpers = require('spec.e2e.adapters.helpers')
local e2e_helpers = require('spec.helpers.e2e_helpers')

--- Temporarily block all telescope modules from being required
--- @return function restore Call to restore telescope availability
local function block_telescope()
  local blocked = {}
  local saved = {}

  -- Save and remove all loaded telescope modules
  for key, value in pairs(package.loaded) do
    if key:match('^telescope') then
      saved[key] = value
      package.loaded[key] = nil
    end
  end

  -- Also clear telescope-orgmode adapter cache so it reloads cleanly
  package.loaded['telescope-orgmode.adapters.telescope'] = nil

  -- Install a loader that blocks telescope requires
  -- LuaJIT/Lua 5.1 uses package.loaders, Lua 5.2+ uses package.searchers
  local searchers = package.searchers or package.loaders
  local function blocker(modname)
    if modname:match('^telescope%.') or modname == 'telescope' then
      return function()
        error('telescope is not installed (blocked by test)')
      end
    end
  end
  table.insert(searchers, 1, blocker)

  -- Return restore function
  return function()
    -- Remove blocker
    for i, s in ipairs(searchers) do
      if s == blocker then
        table.remove(searchers, i)
        break
      end
    end

    -- Restore saved modules
    for key, value in pairs(saved) do
      package.loaded[key] = value
    end
  end
end

describe('[Integration: Snacks without Telescope]', function()
  local restore_telescope

  before_each(function()
    e2e_helpers.create_test_org_files()
    e2e_helpers.setup_orgmode_with_test_files()
    -- Reset telescope-orgmode module cache to force fresh adapter loading
    package.loaded['telescope-orgmode'] = nil
    package.loaded['telescope-orgmode.adapters.snacks'] = nil
    package.loaded['telescope-orgmode.entry_maker.headlines'] = nil
    package.loaded['telescope-orgmode.entry_maker.orgfiles'] = nil
    restore_telescope = block_telescope()
  end)

  after_each(function()
    -- Clean up pickers first (before restoring telescope)
    pcall(function()
      local picker = e2e_helpers.get_current_picker_snacks()
      if picker then
        e2e_helpers.close_picker_snacks(picker)
      end
    end)
    helpers.close_all_pickers()
    helpers.close_all_buffers()

    -- Restore telescope availability for other tests
    if restore_telescope then
      restore_telescope()
    end
  end)

  describe('module loading', function()
    it('should load entry_maker/headlines without telescope', function()
      assert.has_no.errors(function()
        require('telescope-orgmode.entry_maker.headlines')
      end)
    end)

    it('should load entry_maker/orgfiles without telescope', function()
      assert.has_no.errors(function()
        require('telescope-orgmode.entry_maker.orgfiles')
      end)
    end)

    it('should load snacks adapter without telescope', function()
      assert.has_no.errors(function()
        require('telescope-orgmode.adapters.snacks')
      end)
    end)
  end)

  describe('data pipeline', function()
    it('should load headlines via get_entries without telescope', function()
      local headlines = require('telescope-orgmode.entry_maker.headlines')
      local results, widths = headlines.get_entries({})
      assert.is_table(results)
      assert.is_true(#results > 0, 'should return headlines from test org files')
      assert.is_table(widths)

      -- Verify entry structure
      local entry = results[1]
      assert.is_string(entry.filename)
      assert.is_table(entry.headline)
    end)

    it('should load orgfiles via get_entries without telescope', function()
      local orgfiles = require('telescope-orgmode.entry_maker.orgfiles')
      local results = orgfiles.get_entries({})
      assert.is_table(results)
      assert.is_true(#results > 0, 'should return org files from test setup')

      -- Verify entry structure
      local entry = results[1]
      assert.is_string(entry.filename)
    end)

    it('should format headline segments for snacks display without telescope', function()
      local headlines = require('telescope-orgmode.entry_maker.headlines')
      local highlight_lib = require('telescope-orgmode.lib.highlights')

      local results, widths = headlines.get_entries({})
      assert.is_true(#results > 0)

      -- This is what the snacks adapter calls for each entry
      local opts = { widths = widths, show_location = true, show_tags = true }
      local segments, text = highlight_lib.get_headline_segments(results[1].headline, results[1].filename, opts)
      assert.is_table(segments)
      assert.is_true(#segments > 0, 'should produce display segments')
      assert.is_string(text)
      assert.is_true(#text > 0, 'should produce search text')
    end)
  end)

  describe('picker creation', function()
    it('should open search_headings picker without telescope', function()
      local tom = require('telescope-orgmode')
      tom.setup({ adapter = 'snacks' })

      local ok, err = pcall(tom.search_headings)
      assert.is_true(ok, 'search_headings should work without telescope: ' .. tostring(err))

      pcall(function()
        local picker = e2e_helpers.get_current_picker_snacks()
        if picker then
          e2e_helpers.close_picker_snacks(picker)
        end
      end)
    end)

    it('should open refile_heading picker without telescope', function()
      local tom = require('telescope-orgmode')
      tom.setup({ adapter = 'snacks' })

      local ok, err = pcall(tom.refile_heading)
      assert.is_true(ok, 'refile_heading should work without telescope: ' .. tostring(err))

      pcall(function()
        local picker = e2e_helpers.get_current_picker_snacks()
        if picker then
          e2e_helpers.close_picker_snacks(picker)
        end
      end)
    end)

    it('should open insert_link picker without telescope', function()
      vim.cmd('new')
      local tom = require('telescope-orgmode')
      tom.setup({ adapter = 'snacks' })

      local ok, err = pcall(tom.insert_link)
      assert.is_true(ok, 'insert_link should work without telescope: ' .. tostring(err))

      pcall(function()
        local picker = e2e_helpers.get_current_picker_snacks()
        if picker then
          e2e_helpers.close_picker_snacks(picker)
        end
      end)
      vim.cmd('bdelete!')
    end)
  end)

  describe('error handling', function()
    it('should show clear error when adapter fails and telescope unavailable', function()
      local tom = require('telescope-orgmode')
      tom.setup({ adapter = 'nonexistent' })

      local ok, err = pcall(tom.search_headings)
      assert.is_false(ok, 'should error for invalid adapter without telescope fallback')
      assert.matches('not available', tostring(err))
    end)
  end)
end)
