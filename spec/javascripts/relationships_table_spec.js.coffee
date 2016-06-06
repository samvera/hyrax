describe 'RelationshipsTable', ->
  control = require('sufia/relationships/table')
  form = null
  element = null
  btn_remove = null
  btn_add = null
  btn_edit = null
  input = null
  message = null
  test_fixtures = TestFixtures
  test_responses = TestResponses
  deferred_ajax = null

  beforeEach ->
    form = $(test_fixtures.relationships_table.html)
    element = form.find("table")
    btn_remove = element.find('.btn-remove-row')
    btn_add = element.find('.btn-add-row')
    btn_edit = element.find('.edit')
    input = element.find('.new-form-control')
    message = element.find('.message')
    target = new control.RelationshipsTable(element)
    jasmine.Ajax.install()
    deferred_ajax = new jQuery.Deferred()
    spyOn($,'ajax').and.returnValue(deferred_ajax)
    spyOn($,'getJSON').and.callFake((url, success) ->
      success(test_responses.relationships_table.query_url_success))

  afterEach ->
    jasmine.Ajax.uninstall()

  describe 'when adding/removing a row', ->
    # the new-row is properly rendered
    it 'only displays one new row with an add button visible', ->
      expect(btn_remove.hasClass("hidden")).toBeTruthy()
      expect(btn_edit.hasClass("hidden")).toBeTruthy()
      expect(btn_add.hasClass("hidden")).toBeFalsy()

    it 'clicks add with a valid id', ->
      input.val(test_fixtures.relationships_table.parent_id)
      btn_add.click()
      deferred_ajax.resolve(test_responses.relationships_table.ajax_add_success)
      expect(message.hasClass("hidden")).toBeTruthy()
      expect(element.find("tbody tr").length).toEqual(2)

    it 'clicks add with an invalid id', ->
      input.val('invalid')
      btn_add.click()
      deferred_ajax.reject(test_responses.relationships_table.ajax_error)
      expect(message.hasClass("hidden")).toBeFalsy()
      expect(element.find("tbody tr").length).toEqual(1)

    it 'clicks add without an id', ->
      expect(message.hasClass("hidden")).toBeTruthy()
      btn_add.click()
      expect(message.hasClass("hidden")).toBeFalsy()
      expect(message.text()).toContain("ID cannot be empty")
      expect(element.find("tbody tr").length).toEqual(1)

    it 'clicks remove to remove a work', ->
      input.val(test_fixtures.relationships_table.parent_id)
      btn_add.click()
      deferred_ajax.resolve(test_responses.relationships_table.ajax_add_success)
      expect(element.find("tbody tr").length).toEqual(2)
      parent_row = element.find("tbody tr:first")
      parent_delete = parent_row.find(".btn-remove-row")
      parent_delete.click()
      deferred_ajax.resolve(test_responses.relationships_table.ajax_remove_success)
      expect(element.find("tbody tr").length).toEqual(1)

    it 'clicks add with a duplicate id', ->
      input.val(test_fixtures.relationships_table.parent_id)
      btn_add.click()
      deferred_ajax.resolve(test_responses.relationships_table.ajax_add_success)
      expect(element.find("tbody tr").length).toEqual(2)
      input = element.find("tbody tr:nth-child(2) .new-form-control")
      input.val(test_fixtures.relationships_table.parent_id)
      btn_add = element.find("tbody tr:nth-child(2) .btn-add-row")
      btn_add.click()
      message = element.find("tbody tr:nth-child(2) .message")
      expect(element.find("tbody tr").length).toEqual(2)
      expect(message.hasClass("hidden")).toBeFalsy()
      expect(message.text()).toContain("Work is already related")
