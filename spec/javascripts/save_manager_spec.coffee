describe "FileManager Save Button", ->
  savem = require('hyrax/file_manager/save_manager')
  save_manager = null
  handler = null
  deferred_result = null
  beforeEach () ->
    loadFixtures('save_button.html')
    save_manager = new savem
    deferred_result = $.Deferred()
    handler = {
      persist: () =>
        deferred_result
    }
  describe "#push_changed", ->
    it "marks that object as changed", ->
      save_manager.push_changed(handler)

      expect(save_manager.is_changed).toEqual(true)
    it "enables the save button", ->
      save_manager.push_changed(handler)

      expect($("button.disabled").length).toEqual(0)
    it "doesn't add it twice", ->
      save_manager.push_changed(handler)
      save_manager.push_changed(handler)

      expect(save_manager.elements).toEqual([handler])
  describe "#mark_unchanged", ->
    describe "when it was never marked changed", ->
      it "no-ops", ->
        save_manager.mark_unchanged(handler)

        expect(save_manager.elements).toEqual([])
    describe "when it was previously marked changed", ->
      it "removes it", ->
        save_manager.push_changed(handler)
        save_manager.mark_unchanged(handler)

        expect(save_manager.is_changed).toEqual(false)
      it "disables the save button", ->
        save_manager.push_changed(handler)
        save_manager.mark_unchanged(handler)

        expect($("button.disabled").length).toEqual(1)
  describe "#persist", ->
    it "is called by clicking the save button", ->
      Blacklight.activate();
      spyOn(save_manager, "persist").and.callThrough()
      save_manager.push_changed(handler)

      $("button").click()
      console.log(save_manager)
      expect(save_manager.persist).toHaveBeenCalled()
    it "sets the text to be saving...", ->
      save_manager.push_changed(handler)
      save_manager.persist()

      expect($("button").hasClass("disabled")).toEqual(true)
      expect($("button").text()).toEqual("Saving...")
    it "calls persist on each registered handler", ->
      spyOn(handler, "persist").and.callThrough()
      save_manager.push_changed(handler)
      save_manager.persist()

      expect(handler.persist).toHaveBeenCalled()
    describe "when the changed elements are done persisting", ->
      it "resets everything", ->
        save_manager.push_changed(handler)
        save_manager.persist()

        # Resolve the promise - like an Ajax request.
        deferred_result.resolve()

        expect($("button").hasClass("disabled")).toEqual(true)
        expect($("button").text()).toEqual("Save")
        expect(save_manager.is_changed).toEqual(false)
    describe "when the changed elements have failed to persist", ->
      it "fixes the text but keeps the button enabled", ->
        save_manager.push_changed(handler)
        save_manager.persist()

        # Reject the promise.
        deferred_result.reject()

        expect($("button").hasClass("disabled")).toEqual(false)
        expect($("button").text()).toEqual("Save")
        expect(save_manager.is_changed).toEqual(true)
