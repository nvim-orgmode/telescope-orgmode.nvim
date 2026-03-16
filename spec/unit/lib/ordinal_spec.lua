local ordinal = require('telescope-orgmode.lib.ordinal')

describe('[Unit: lib/ordinal]', function()
  describe('DEFAULT_FIELD_ORDER', function()
    it('contains all known fields', function()
      assert.same({ 'state', 'priority', 'headline', 'location', 'tags', 'properties' }, ordinal.DEFAULT_FIELD_ORDER)
    end)
  end)

  describe('resolve_fields', function()
    it('returns explicit ordinal_fields when set', function()
      local opts = { ordinal_fields = { 'state', 'headline' } }
      assert.same({ 'state', 'headline' }, ordinal.resolve_fields(opts))
    end)

    it('derives fields from show_* flags when ordinal_fields is nil', function()
      local opts = {
        show_todo_state = true,
        show_priority = true,
        show_location = true,
        show_tags = true,
        show_properties = {},
      }
      local fields = ordinal.resolve_fields(opts)
      assert.same({ 'state', 'priority', 'headline', 'location', 'tags' }, fields)
    end)

    it('always includes headline in default fields', function()
      local opts = {
        show_todo_state = false,
        show_priority = false,
        show_location = false,
        show_tags = false,
        show_properties = {},
      }
      local fields = ordinal.resolve_fields(opts)
      assert.same({ 'headline' }, fields)
    end)

    it('includes properties when show_properties has entries', function()
      local opts = {
        show_todo_state = false,
        show_priority = false,
        show_location = false,
        show_tags = false,
        show_properties = { { name = 'ID' } },
      }
      local fields = ordinal.resolve_fields(opts)
      assert.same({ 'headline', 'properties' }, fields)
    end)

    it('respects individual show_* flags', function()
      local opts = {
        show_todo_state = true,
        show_priority = false,
        show_location = false,
        show_tags = true,
        show_properties = {},
      }
      local fields = ordinal.resolve_fields(opts)
      assert.same({ 'state', 'headline', 'tags' }, fields)
    end)
  end)

  describe('build', function()
    local function make_data(overrides)
      return vim.tbl_extend('force', {
        headline = {
          todo_value = nil,
          priority = nil,
          properties = {},
        },
        location = 'test.org:10',
        tags = '',
        line = '* Test Headline',
        opts = { show_properties = {} },
      }, overrides or {})
    end

    it('builds string in given field order', function()
      local data = make_data({
        headline = { todo_value = 'TODO', priority = 'A', properties = {} },
      })
      local result = ordinal.build({ 'state', 'headline' }, data)
      assert.equals('TODO * Test Headline', result)
    end)

    it('respects field order - headline first', function()
      local data = make_data({
        headline = { todo_value = 'TODO', priority = nil, properties = {} },
      })
      local result = ordinal.build({ 'headline', 'state' }, data)
      assert.equals('* Test Headline TODO', result)
    end)

    it('skips nil values', function()
      local data = make_data() -- no todo_value, no priority
      local result = ordinal.build({ 'state', 'priority', 'headline' }, data)
      assert.equals('* Test Headline', result)
    end)

    it('skips empty tags', function()
      local data = make_data({ tags = '' })
      local result = ordinal.build({ 'tags', 'headline' }, data)
      assert.equals('* Test Headline', result)
    end)

    it('includes tags when present', function()
      local data = make_data({ tags = 'work:urgent' })
      local result = ordinal.build({ 'tags', 'headline' }, data)
      assert.equals('work:urgent * Test Headline', result)
    end)

    it('handles tags as table', function()
      local data = make_data({ tags = { 'work', 'urgent' } })
      local result = ordinal.build({ 'tags', 'headline' }, data)
      assert.equals('work:urgent * Test Headline', result)
    end)

    it('formats priority with brackets', function()
      local data = make_data({
        headline = { todo_value = nil, priority = 'A', properties = {} },
      })
      local result = ordinal.build({ 'priority', 'headline' }, data)
      assert.equals('[#A] * Test Headline', result)
    end)

    it('includes location', function()
      local data = make_data()
      local result = ordinal.build({ 'location', 'headline' }, data)
      assert.equals('test.org:10 * Test Headline', result)
    end)

    it('concatenates multiple property values', function()
      local data = make_data({
        headline = {
          todo_value = nil,
          priority = nil,
          properties = { ID = 'abc-123', EFFORT = '2h' },
        },
        opts = {
          show_properties = {
            { name = 'ID' },
            { name = 'EFFORT' },
          },
        },
      })
      local result = ordinal.build({ 'properties', 'headline' }, data)
      assert.equals('abc-123 2h * Test Headline', result)
    end)

    it('skips empty property values', function()
      local data = make_data({
        headline = {
          todo_value = nil,
          priority = nil,
          properties = { ID = '', EFFORT = '2h' },
        },
        opts = {
          show_properties = {
            { name = 'ID' },
            { name = 'EFFORT' },
          },
        },
      })
      local result = ordinal.build({ 'properties', 'headline' }, data)
      assert.equals('2h * Test Headline', result)
    end)

    it('handles missing headline properties gracefully', function()
      local data = make_data({
        headline = { todo_value = nil, priority = nil, properties = nil },
        opts = { show_properties = { { name = 'ID' } } },
      })
      local result = ordinal.build({ 'properties', 'headline' }, data)
      assert.equals('* Test Headline', result)
    end)

    it('builds full ordinal with all fields', function()
      local data = make_data({
        headline = {
          todo_value = 'TODO',
          priority = 'A',
          properties = { ID = 'x1' },
        },
        tags = 'work',
        opts = { show_properties = { { name = 'ID' } } },
      })
      local result = ordinal.build({ 'state', 'priority', 'headline', 'location', 'tags', 'properties' }, data)
      assert.equals('TODO [#A] * Test Headline test.org:10 work x1', result)
    end)

    it('returns empty string for empty fields list', function()
      local data = make_data()
      local result = ordinal.build({}, data)
      assert.equals('', result)
    end)

    it('ignores unknown field names', function()
      local data = make_data()
      local result = ordinal.build({ 'unknown', 'headline' }, data)
      assert.equals('* Test Headline', result)
    end)
  end)
end)
