describe "FileManagerMember", ->
  filemm = require('hyrax/file_manager/member')
  file_manager_member = null
  save_manager = null
  beforeEach () ->
    loadFixtures('file_manager_member.html')
    save_manager = {
      push_changed: () -> {},
      mark_unchanged: () -> {}
    }
    file_manager_member = new filemm.FileManagerMember($("li"), save_manager)
  describe "#is_changed", ->
    it "is true when the form's label input is changed", ->
      $("#file_set_title").val("testing")
      $("#file_set_title").change()

      expect(file_manager_member.is_changed).toEqual(true)
    it "is false when the form's label input isn't changed", ->
      $("#file_set_title").change()

      expect(file_manager_member.is_changed).toEqual(false)
    it "is false when the form's label input returns", ->
      initial_val = $("#file_set_title").val()
      $("#file_set_title").val("testing")
      $("#file_set_title").change()
      $("#file_set_title").val(initial_val)
      $("#file_set_title").change()

      expect(file_manager_member.is_changed).toEqual(false)
    it "triggers save_manager's push_changed when changed", ->
      spyOn(save_manager, "push_changed")
      $("#file_set_title").val("testing")
      $("#file_set_title").change()

      expect(save_manager.push_changed).toHaveBeenCalledWith(file_manager_member)
    it "triggers save_manager's mark_unchanged when no longer changed", ->
      spyOn(save_manager, "mark_unchanged")
      initial_val = $("#file_set_title").val()
      $("#file_set_title").val("testing")
      $("#file_set_title").change()
      $("#file_set_title").val(initial_val)
      $("#file_set_title").change()

      expect(save_manager.mark_unchanged).toHaveBeenCalledWith(file_manager_member)
    it "doesn't trigger save_manager's mark_unchanged when there are still changed elements", ->
      spyOn(save_manager, "mark_unchanged")
      file_manager_member.elements.push {}
      initial_val = $("#file_set_title").val()
      $("#file_set_title").val("testing")
      $("#file_set_title").change()
      $("#file_set_title").val(initial_val)
      $("#file_set_title").change()

      expect(save_manager.mark_unchanged).not.toHaveBeenCalled()
  describe "#persist", ->
    describe "when nothing has changed", ->
      it "returns a resolved deferred object", ->
        expect(file_manager_member.persist().state()).toEqual("resolved")
    describe "when updates need to be sent", ->
      request = null
      beforeEach () ->
        jasmine.Ajax.install()
      afterEach () ->
        jasmine.Ajax.uninstall()
      it "returns a deferred object which is resolved with the ajax request", ->
        $("#file_set_title").val("testing")
        $("#file_set_title").change()
        result = file_manager_member.persist()
        request = jasmine.Ajax.requests.mostRecent()

        expect(result.state()).toEqual("pending")

        request.respondWith(TestResponses.file_manager_member.success)

        expect(result.state()).toEqual("resolved")
        expect(file_manager_member.is_changed).toEqual(false)
      it "rejects the deferred object when the ajax request fails", ->
        $("#file_set_title").val("testing")
        $("#file_set_title").change()
        result = file_manager_member.persist()
        request = jasmine.Ajax.requests.mostRecent()

        expect(result.state()).toEqual("pending")

        request.respondWith(TestResponses.file_manager_member.failure)

        expect(result.state()).toEqual("rejected")
        expect(file_manager_member.is_changed).toEqual(true)
