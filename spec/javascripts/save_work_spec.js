describe("SaveWorkControl", function() {
  var control = require('sufia/save_work/save_work_control');

  describe("validateMetadata", function() {
    var mockCheckbox = {
      check: function() { },
      uncheck: function() { },
    };
    var element = {
      size: function() { return 1 },
      closest: function() { return {} }
    };

    beforeEach(function() {
      target = new control.SaveWorkControl(element);
      target.requiredMetadata = mockCheckbox;
      spyOn(mockCheckbox, 'check').and.stub();
      spyOn(mockCheckbox, 'uncheck').and.stub();
    });

    describe("when required metadata is present", function() {
      beforeEach(function() {
        target.requiredFields = {
          areComplete: true
        };
      });
      it("is complete", function() {
        target.validateMetadata();
        expect(mockCheckbox.uncheck.calls.count()).toEqual(0);
        expect(mockCheckbox.check.calls.count()).toEqual(1);
      });
    });

    describe("when a required metadata is missing", function() {
      beforeEach(function() {
        target.requiredFields = {
          areComplete: false
        };
      });
      it("is incomplete", function() {
        target.validateMetadata();
        expect(mockCheckbox.uncheck.calls.count()).toEqual(1);
        expect(mockCheckbox.check.calls.count()).toEqual(0);
      });
    });
  });

  describe("validateFiles", function() {
    var mockCheckbox = {
      check: function() { },
      uncheck: function() { },
    };
    var form_id = 'new_generic_work';
    var form = { attr: function() { return form_id } };
    var element = {
      size: function() { return 1 },
      closest: function() { return form }
    };

    beforeEach(function() {
      target = new control.SaveWorkControl(element);
      target.requiredFiles = mockCheckbox;
      spyOn(mockCheckbox, 'check').and.stub();
      spyOn(mockCheckbox, 'uncheck').and.stub();
    });

    describe("when required files are present", function() {
      beforeEach(function() {
        target.uploads = {
          hasFiles: true
        };
      });
      it("is complete", function() {
        target.validateFiles();
        expect(mockCheckbox.uncheck.calls.count()).toEqual(0);
        expect(mockCheckbox.check.calls.count()).toEqual(1);
      });
    });

    describe("when a required files are missing", function() {
      beforeEach(function() {
        target.uploads = {
          hasFiles: false
        };
      });

      it("is incomplete", function() {
        target.validateFiles();
        expect(mockCheckbox.uncheck.calls.count()).toEqual(1);
        expect(mockCheckbox.check.calls.count()).toEqual(0);
      });
    });

    describe("when a required files are missing and it's an edit form", function() {
      beforeEach(function() {
        form_id = 'edit_generic_work'
      });
      it("is complete", function() {
        target.validateFiles();
        expect(mockCheckbox.uncheck.calls.count()).toEqual(0);
        expect(mockCheckbox.check.calls.count()).toEqual(1);
      });
    });
  });

  describe("activate", function() {
    beforeEach(function() {
      setFixtures('<form id="new_generic_work"><aside id="form-progress><ul><li id="required-metadata"><li id="required-files"></ul></aside></form>');
      target = new control.SaveWorkControl($('#form-progress'));
      target.activate()
    });

    it("is complete", function() {
      expect(target.requiredFields).not.toBe(null);
      expect(target.uploads).not.toBe(null);
      expect(target.requiredMetadata).not.toBe(null);
      expect(target.requiredFiles).not.toBe(null);
    });
  });
});


