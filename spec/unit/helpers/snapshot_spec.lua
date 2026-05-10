describe('[Helper: snapshot]', function()
  local snapshot = require('spec.helpers.snapshot')

  describe('project_headline', function()
    it('projects all documented fields, drops unknown extras', function()
      local entry = {
        filename = '/tmp/a.org',
        line_number = 3,
        title = 'Set up CI',
        level = 1,
        todo_value = 'TODO',
        todo_type = 'TODO',
        priority = 'A',
        all_tags = { 'work', 'urgent' },
        is_archived = false,
        properties = { ID = 'x', CATEGORY = 'infra' },
        -- noise that must not appear in projection:
        _ts_node = { kind = 'opaque' },
        get_title = function() end,
      }

      local out = snapshot.project_headline(entry)

      assert.are.same({
        filename = '/tmp/a.org',
        line_number = 3,
        title = 'Set up CI',
        level = 1,
        todo_value = 'TODO',
        todo_type = 'TODO',
        priority = 'A',
        all_tags = { 'work', 'urgent' },
        is_archived = false,
        properties = { ID = 'x', CATEGORY = 'infra' },
      }, out)
      assert.is_nil(out._ts_node)
      assert.is_nil(out.get_title)
    end)

    it('substitutes nil-safe defaults for missing optional fields', function()
      local entry = {
        filename = '/tmp/b.org',
        line_number = 1,
        title = 'Bare headline',
        level = 1,
      }

      local out = snapshot.project_headline(entry)

      assert.are.same({}, out.all_tags)
      assert.is_false(out.is_archived)
      assert.is_nil(out.todo_value)
      assert.are.equal('', out.todo_type)
      assert.is_nil(out.priority)
      assert.are.same({}, out.properties)
    end)

    it('returns tags in their original order', function()
      -- Stability requirement: projection must NOT mutate tag order;
      -- callers that need alphabetic order do that themselves.
      local out = snapshot.project_headline({
        filename = '/tmp/c.org',
        line_number = 2,
        title = 'Tagged',
        level = 2,
        all_tags = { 'work', 'urgent', 'note' },
      })
      assert.are.same({ 'work', 'urgent', 'note' }, out.all_tags)
    end)
  end)

  describe('project_file', function()
    it('keeps only filename + title', function()
      local entry = {
        filename = '/tmp/x.org',
        title = 'Project X',
        opaque = { ts = true },
      }

      local out = snapshot.project_file(entry)

      assert.are.same({
        filename = '/tmp/x.org',
        title = 'Project X',
      }, out)
    end)

    it('falls back to filename stem when title missing', function()
      local out = snapshot.project_file({ filename = '/tmp/notes.org' })
      assert.are.equal('notes', out.title)
    end)
  end)

  describe('project_tag', function()
    it('projects tag entry with defaults for optional fields', function()
      local out = snapshot.project_tag({ tag = 'work' })
      assert.are.same({ tag = 'work', count = 1, files = {} }, out)
    end)

    it('keeps explicit count and files', function()
      local out = snapshot.project_tag({
        tag = 'urgent',
        count = 3,
        files = { '/tmp/a.org', '/tmp/b.org' },
      })
      assert.are.same({
        tag = 'urgent',
        count = 3,
        files = { '/tmp/a.org', '/tmp/b.org' },
      }, out)
    end)
  end)

  describe('project_list', function()
    it('maps a projector across a list', function()
      local entries = {
        { filename = '/tmp/a.org', title = 'A' },
        { filename = '/tmp/b.org' },
      }
      local out = snapshot.project_list(entries, snapshot.project_file)
      assert.are.same({
        { filename = '/tmp/a.org', title = 'A' },
        { filename = '/tmp/b.org', title = 'b' },
      }, out)
    end)
  end)
end)
