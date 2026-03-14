--- Smoke Tests for Picker Adapters
--- These tests verify basic initialization and creation without crashes

local helpers = require('spec.e2e.adapters.helpers')

local has_snacks = pcall(require, 'snacks')

describe('[Integration: Adapter Smoke Tests]', function()
  after_each(function()
    helpers.close_all_pickers()
    helpers.close_all_buffers()
  end)

  describe('Module Loading', function()
    it('should load Snacks adapter without errors', function()
      assert.has_no.errors(function()
        require('telescope-orgmode.adapters.snacks')
      end)
    end)

    it('should load Telescope adapter without errors', function()
      assert.has_no.errors(function()
        require('telescope-orgmode.adapters.telescope')
      end)
    end)
  end)

  describe('Basic Initialization', function()
    (has_snacks and it or pending)('should create Snacks picker without crash', function()
      -- Create a temporary org file so we have content
      local test_file = helpers.create_temp_org_file({
        '* Test Headline 1',
        '** Subheadline',
        '* Test Headline 2',
      })

      -- Setup orgmode with the test file
      require('orgmode').setup({
        org_agenda_files = { test_file },
      })

      -- This should not crash
      assert.has_no.errors(function()
        require('telescope-orgmode').search_headings({ adapter = 'snacks' })
        vim.wait(200) -- Give it time to initialize
        helpers.close_all_pickers() -- Clean up immediately
      end)
    end)

    it('should create Telescope picker without crash', function()
      -- Create a temporary org file so we have content
      local test_file = helpers.create_temp_org_file({
        '* Test Headline 1',
        '** Subheadline',
        '* Test Headline 2',
      })

      -- Setup orgmode with the test file
      require('orgmode').setup({
        org_agenda_files = { test_file },
      })

      -- This should not crash
      assert.has_no.errors(function()
        require('telescope-orgmode').search_headings({ adapter = 'telescope' })
        vim.wait(200) -- Give it time to initialize
        helpers.close_all_pickers() -- Clean up immediately
      end)
    end)
  end)

  describe('Adapter Selection', function()
    (has_snacks and it or pending)('should respect adapter parameter in options', function()
      -- Create a temporary org file
      local test_file = helpers.create_temp_org_file({
        '* Test Headline',
      })

      -- Setup orgmode
      require('orgmode').setup({
        org_agenda_files = { test_file },
      })

      -- Should not error when specifying adapter explicitly
      assert.has_no.errors(function()
        require('telescope-orgmode').search_headings({ adapter = 'snacks' })
        vim.wait(100)
        helpers.close_all_pickers()
      end)

      assert.has_no.errors(function()
        require('telescope-orgmode').search_headings({ adapter = 'telescope' })
        vim.wait(100)
        helpers.close_all_pickers()
      end)
    end)
  end)
end)
