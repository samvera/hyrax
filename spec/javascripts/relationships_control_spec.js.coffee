describe 'RelationshipsControl', ->
  RelationshipsControl = require('hyrax/relationships/control')
  element = null
  target = null
  test_fixtures = TestFixtures

  beforeEach ->
    fixture = setFixtures(test_fixtures.relationships_table.html)
    element = $("table")
    target = new RelationshipsControl(element, 'work_members_attributes', 'tmpl-child-work')
    jasmine.Ajax.install()

  afterEach ->
    jasmine.Ajax.uninstall()

  describe 'attemptToAddRow', ->
    it 'has errors when nothing is selected', ->
      target.attemptToAddRow()
      expect(target.errors).toEqual([ 'ID cannot be empty.' ])

    it 'creates a row when something is selected', ->
      spyOn(target.input, 'val').and.returnValue('123')
      spyOn(target, 'searchData').and.returnValue({ id: '123', text: 'foo bar' })
      expect(target.registry.nextIndex()).toEqual(0)
      target.attemptToAddRow()
      expect(target.errors).toBeNull()
      expect(target.registry.nextIndex()).toEqual(1)
