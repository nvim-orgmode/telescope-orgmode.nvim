-- End-to-end tests for the Snacks adapter's picker_opts merge.
-- The capture mock intercepts `require('snacks').picker(opts)` and
-- exposes the opts table for assertions.

local helpers = require('spec.integration.adapters.snacks_helpers')

describe('[E2E: Snacks picker_opts merge]', function()
  local captured
  local config
  local snapshot

  before_each(function()
    -- Reload adapter and entry module so the adapter picks up the mock
    -- via `require('snacks')` and state is reproducible.
    package.loaded['telescope-orgmode.adapters.snacks'] = nil
    package.loaded['telescope-orgmode'] = nil

    config = require('telescope-orgmode.lib.config')
    snapshot = helpers.snapshot_config(config)

    captured = helpers.setup_snacks_mock()
  end)

  after_each(function()
    helpers.teardown()
    helpers.restore_config(config, snapshot)
    package.loaded['telescope-orgmode.adapters.snacks'] = nil
    package.loaded['telescope-orgmode'] = nil
  end)

  ---Drive the snacks search_headings path with the given user opts.
  ---@param call_opts table|nil
  local function run_search(call_opts)
    local tom = require('telescope-orgmode')
    tom.search_headings(vim.tbl_extend('force', { adapter = 'snacks' }, call_opts or {}))
  end

  describe('mock harness', function()
    it('captures picker_opts via mock', function()
      require('telescope-orgmode').setup({ adapter = 'snacks' })
      run_search()
      assert.equals(1, #captured)
      assert.is_table(captured[1])
    end)
  end)

  describe('setup default', function()
    it('applies picker_defaults.search_headings.snacks.layout to final picker_opts', function()
      require('telescope-orgmode').setup({
        adapter = 'snacks',
        picker_defaults = {
          search_headings = {
            snacks = { layout = 'vertical' },
          },
        },
      })
      run_search()
      assert.equals('vertical', captured[1].layout)
    end)
  end)

  describe('per-call override', function()
    it('per-call snacks.layout overrides setup default', function()
      require('telescope-orgmode').setup({
        adapter = 'snacks',
        picker_defaults = {
          search_headings = {
            snacks = { layout = 'vertical' },
          },
        },
      })
      run_search({ snacks = { layout = 'horizontal' } })
      assert.equals('horizontal', captured[1].layout)
    end)
  end)

  describe('adapter-owned protection', function()
    it('does not let user override adapter-owned fields', function()
      local user_format = function()
        return 'USER_FORMAT'
      end
      local user_confirm = function()
        return 'USER_CONFIRM'
      end
      require('telescope-orgmode').setup({
        adapter = 'snacks',
        picker_defaults = {
          search_headings = {
            snacks = {
              format = user_format,
              frecency = false,
              preview = 'none',
              confirm = user_confirm,
            },
          },
        },
      })
      run_search()
      local opts = captured[1]
      assert.is_not_equal(user_format, opts.format, 'adapter must replace user format')
      assert.is_true(opts.frecency)
      assert.equals('preview', opts.preview)
      assert.is_not_equal(user_confirm, opts.confirm, 'adapter must replace user confirm')
      assert.is_function(opts.confirm)
    end)
  end)

  describe('previewers passthrough', function()
    it('passes user previewers (plural) through', function()
      local custom_previewer = function() end
      require('telescope-orgmode').setup({
        adapter = 'snacks',
        picker_defaults = {
          search_headings = {
            snacks = {
              previewers = { my_custom = custom_previewer },
            },
          },
        },
      })
      run_search()
      local opts = captured[1]
      assert.is_table(opts.previewers)
      assert.equals(custom_previewer, opts.previewers.my_custom)
    end)
  end)

  describe('key merge', function()
    it('merges user-provided win.input.keys additively', function()
      require('telescope-orgmode').setup({
        adapter = 'snacks',
        picker_defaults = {
          search_headings = {
            snacks = {
              win = {
                input = {
                  keys = {
                    ['<C-x>'] = 'my_action',
                    ['<C-Space>'] = 'user_override',
                  },
                },
              },
            },
          },
        },
      })
      run_search()
      local keys = captured[1].win.input.keys
      assert.equals('my_action', keys['<C-x>'])
      -- Adapter binding wins; adapter keys are tables, user values are strings.
      assert.is_not_equal('user_override', keys['<C-Space>'])
      assert.is_table(keys['<C-Space>'])
    end)
  end)

  describe('catch-all passthrough', function()
    it('passes arbitrary snacks options (matcher/sort/formatters) through', function()
      local matcher = { fuzzy = false }
      local sort = { fields = { 'foo' } }
      local formatters = { file = { truncate = 20 } }
      require('telescope-orgmode').setup({
        adapter = 'snacks',
        picker_defaults = {
          search_headings = {
            snacks = {
              matcher = matcher,
              sort = sort,
              formatters = formatters,
            },
          },
        },
      })
      run_search()
      local opts = captured[1]
      assert.same(matcher, opts.matcher)
      assert.same(sort, opts.sort)
      assert.same(formatters, opts.formatters)
    end)
  end)
end)
