-- Unit tests for the private Snacks merge helpers (exported as `_name`).

local snacks = require('telescope-orgmode.adapters.snacks')
local config = require('telescope-orgmode.lib.config')

describe('[Unit: snacks merge helpers]', function()
  describe('_merge_input_keys', function()
    it('merges user keys additively, adapter wins on conflict', function()
      local user_keys = {
        ['<C-x>'] = 'my_action',
        ['<C-Space>'] = 'user_override',
      }
      local adapter_keys = {
        ['<C-Space>'] = { function() end, mode = { 'i', 'n' }, desc = 'toggle_mode' },
        ['<C-t>'] = { function() end, mode = { 'i', 'n' }, desc = 'open_tag_picker' },
      }

      local merged = snacks._merge_input_keys(user_keys, adapter_keys)

      assert.equals('my_action', merged['<C-x>'])
      assert.equals(adapter_keys['<C-Space>'], merged['<C-Space>'])
      assert.equals(adapter_keys['<C-t>'], merged['<C-t>'])
    end)

    it('returns adapter keys when user keys are empty', function()
      local adapter_keys = { ['<C-q>'] = 'q_action' }
      local merged = snacks._merge_input_keys({}, adapter_keys)
      assert.equals('q_action', merged['<C-q>'])
    end)

    it('returns user keys when adapter keys are empty', function()
      local user_keys = { ['<C-y>'] = 'y_action' }
      local merged = snacks._merge_input_keys(user_keys, {})
      assert.equals('y_action', merged['<C-y>'])
    end)
  end)

  describe('_build_user_snacks', function()
    local saved_picker_defaults

    before_each(function()
      saved_picker_defaults = vim.deepcopy(config.picker_defaults)
    end)

    after_each(function()
      config.picker_defaults = saved_picker_defaults
    end)

    it('returns empty table when no setup or call snacks', function()
      config.picker_defaults.search_headings.snacks = nil
      local result = snacks._build_user_snacks('search_headings', {})
      assert.same({}, result)
    end)

    it('returns setup snacks when no per-call snacks', function()
      config.picker_defaults.search_headings.snacks = { layout = 'vertical' }
      local result = snacks._build_user_snacks('search_headings', {})
      assert.equals('vertical', result.layout)
    end)

    it('deep-merges setup and per-call snacks opts', function()
      config.picker_defaults.search_headings.snacks = {
        win = { width = 0.9 },
      }
      local base_opts = {
        snacks = {
          win = { height = 0.5 },
        },
      }
      local result = snacks._build_user_snacks('search_headings', base_opts)
      assert.equals(0.9, result.win.width)
      assert.equals(0.5, result.win.height)
    end)

    it('per-call wins over setup at nested keys', function()
      config.picker_defaults.search_headings.snacks = { layout = 'vertical' }
      local base_opts = { snacks = { layout = 'horizontal' } }
      local result = snacks._build_user_snacks('search_headings', base_opts)
      assert.equals('horizontal', result.layout)
    end)

    it('preserves setup win.input.keys when per-call has no keys', function()
      config.picker_defaults.search_headings.snacks = {
        win = { input = { keys = { ['<C-x>'] = 'setup_action' } } },
      }
      local result = snacks._build_user_snacks('search_headings', {})
      assert.equals('setup_action', result.win.input.keys['<C-x>'])
    end)
  end)

  describe('_merge_snacks_opts', function()
    it('lets adapter-owned fields win over user-set ones', function()
      local user_snacks = {
        format = function()
          return 'USER'
        end,
        title = 'User Title',
        layout = 'vertical',
      }
      local adapter_fn = function()
        return 'ADAPTER'
      end
      local adapter_owned = {
        title = 'Adapter Title',
        items = {},
        pattern = '',
        preview = 'preview',
        frecency = true,
        format = adapter_fn,
      }
      local result = snacks._merge_snacks_opts(user_snacks, adapter_owned, {})
      assert.equals('Adapter Title', result.title)
      assert.equals(adapter_fn, result.format)
      assert.is_true(result.frecency)
      assert.equals('preview', result.preview)
    end)

    it('preserves user layout/win/previewers', function()
      local user_snacks = {
        layout = 'vertical',
        win = { width = 0.99 },
        previewers = { my_custom = function() end },
      }
      local adapter_owned = {
        title = 'X',
        items = {},
        pattern = '',
        preview = 'preview',
        frecency = true,
        format = function() end,
      }
      local result = snacks._merge_snacks_opts(user_snacks, adapter_owned, {})
      assert.equals('vertical', result.layout)
      assert.equals(0.99, result.win.width)
      assert.is_function(result.previewers.my_custom)
    end)

    it('lets user-set keys survive (additive) while adapter keys win on conflict', function()
      local user_snacks = {
        win = {
          input = {
            keys = {
              ['<C-x>'] = 'user_x',
              ['<C-Space>'] = 'user_override',
            },
          },
        },
      }
      local adapter_owned = {
        title = 'X',
        items = {},
        pattern = '',
        preview = 'preview',
        frecency = true,
        format = function() end,
      }
      local merged_keys = {
        ['<C-x>'] = 'user_x',
        ['<C-Space>'] = 'adapter_toggle',
      }
      local result = snacks._merge_snacks_opts(user_snacks, adapter_owned, merged_keys)
      assert.equals('user_x', result.win.input.keys['<C-x>'])
      assert.equals('adapter_toggle', result.win.input.keys['<C-Space>'])
    end)

    it('does not include confirm (adapter sets confirm after merge)', function()
      local user_snacks = {
        confirm = function()
          return 'user_confirm'
        end,
      }
      local adapter_owned = {
        title = 'X',
        items = {},
        pattern = '',
        preview = 'preview',
        frecency = true,
        format = function() end,
      }
      -- `adapter_owned` deliberately omits `confirm`; `create_picker`
      -- assigns it picker-type-specific after the merge.
      local result = snacks._merge_snacks_opts(user_snacks, adapter_owned, {})
      assert.is_function(result.confirm)
    end)
  end)
end)
