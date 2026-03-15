local config = require('telescope-orgmode.lib.config')

describe('[Unit: lib/config]', function()
  describe('defaults', function()
    it('has expected default values', function()
      assert.is_nil(config.defaults.max_depth)
      assert.is_false(config.defaults.archived)
      assert.is_false(config.defaults.only_current_file)
      assert.is_true(config.defaults.show_location)
      assert.is_true(config.defaults.show_tags)
      assert.is_true(config.defaults.show_todo_state)
      assert.is_true(config.defaults.show_priority)
      assert.equals(15, config.defaults.location_max_width)
      assert.equals(15, config.defaults.tags_max_width)
      assert.same({}, config.defaults.show_properties)
    end)
  end)

  describe('merge', function()
    it('returns defaults when no opts provided', function()
      local result = config.merge(nil)
      assert.equals(config.defaults.archived, result.archived)
      assert.equals(config.defaults.show_location, result.show_location)
    end)

    it('merges user options with defaults', function()
      local opts = { max_depth = 3, archived = true }
      local result = config.merge(opts)
      assert.equals(3, result.max_depth)
      assert.is_true(result.archived)
      assert.is_false(result.only_current_file) -- from defaults
    end)

    it('overrides defaults with user options', function()
      local opts = { show_location = false, location_max_width = 20 }
      local result = config.merge(opts)
      assert.is_false(result.show_location)
      assert.equals(20, result.location_max_width)
    end)
  end)

  describe('validate', function()
    it('accepts valid configuration', function()
      local valid_config = config.merge({ max_depth = 3 })
      local valid, err = config.validate(valid_config)
      assert.is_true(valid)
      assert.is_nil(err)
    end)

    it('rejects negative max_depth', function()
      local invalid_config = { max_depth = -1 }
      local valid, err = config.validate(invalid_config)
      assert.is_false(valid)
      assert.is_not_nil(err)
    end)

    it('rejects zero max_depth', function()
      local invalid_config = { max_depth = 0 }
      local valid, err = config.validate(invalid_config)
      assert.is_false(valid)
      assert.is_not_nil(err)
    end)

    it('rejects invalid location_max_width', function()
      local invalid_config = { location_max_width = -5 }
      local valid, err = config.validate(invalid_config)
      assert.is_false(valid)
      assert.is_not_nil(err)
    end)

    it('rejects invalid tags_max_width', function()
      local invalid_config = { tags_max_width = 0 }
      local valid, err = config.validate(invalid_config)
      assert.is_false(valid)
      assert.is_not_nil(err)
    end)

    it('accepts empty show_properties', function()
      local cfg = config.merge({ show_properties = {} })
      local valid, err = config.validate(cfg)
      assert.is_true(valid)
      assert.is_nil(err)
    end)

    it('accepts valid show_properties', function()
      local cfg = {
        show_properties = {
          { name = 'ID', max_width = 12 },
          { name = 'EFFORT', max_width = 6, highlight = 'Number' },
        },
      }
      local valid, err = config.validate(cfg)
      assert.is_true(valid)
      assert.is_nil(err)
    end)

    it('accepts show_properties with name only', function()
      local cfg = { show_properties = { { name = 'CATEGORY' } } }
      local valid, err = config.validate(cfg)
      assert.is_true(valid)
      assert.is_nil(err)
    end)

    it('rejects show_properties entry without name', function()
      local cfg = { show_properties = { { max_width = 10 } } }
      local valid, err = config.validate(cfg)
      assert.is_false(valid)
      assert.matches('show_properties%[1%].name', err)
    end)

    it('rejects show_properties entry with empty name', function()
      local cfg = { show_properties = { { name = '' } } }
      local valid, err = config.validate(cfg)
      assert.is_false(valid)
      assert.matches('show_properties%[1%].name', err)
    end)

    it('rejects show_properties entry with non-string name', function()
      local cfg = { show_properties = { { name = 42 } } }
      local valid, err = config.validate(cfg)
      assert.is_false(valid)
      assert.matches('show_properties%[1%].name', err)
    end)

    it('rejects show_properties with invalid max_width', function()
      local cfg = { show_properties = { { name = 'ID', max_width = 0 } } }
      local valid, err = config.validate(cfg)
      assert.is_false(valid)
      assert.matches('max_width', err)
    end)

    it('rejects show_properties with negative max_width', function()
      local cfg = { show_properties = { { name = 'ID', max_width = -5 } } }
      local valid, err = config.validate(cfg)
      assert.is_false(valid)
      assert.matches('max_width', err)
    end)

    it('rejects show_properties with non-number max_width', function()
      local cfg = { show_properties = { { name = 'ID', max_width = 'big' } } }
      local valid, err = config.validate(cfg)
      assert.is_false(valid)
      assert.matches('max_width', err)
    end)

    it('rejects show_properties with non-string highlight', function()
      local cfg = { show_properties = { { name = 'ID', highlight = 123 } } }
      local valid, err = config.validate(cfg)
      assert.is_false(valid)
      assert.matches('highlight', err)
    end)

    it('rejects non-table show_properties', function()
      local cfg = { show_properties = 'ID' }
      local valid, err = config.validate(cfg)
      assert.is_false(valid)
      assert.matches('show_properties must be a table', err)
    end)

    it('rejects non-table entry in show_properties', function()
      local cfg = { show_properties = { 'ID' } }
      local valid, err = config.validate(cfg)
      assert.is_false(valid)
      assert.matches('show_properties%[1%] must be a table', err)
    end)

    it('reports correct index for invalid entry', function()
      local cfg = {
        show_properties = {
          { name = 'ID' },
          { max_width = 10 }, -- missing name
        },
      }
      local valid, err = config.validate(cfg)
      assert.is_false(valid)
      assert.matches('show_properties%[2%]', err)
    end)
  end)

  describe('get_original_file', function()
    it('returns a string', function()
      local filename = config.get_original_file()
      assert.equals('string', type(filename))
    end)
  end)
end)
