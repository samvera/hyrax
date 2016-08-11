describe("SaveWorkControl", function() {
  var control = require('sufia/save_work/save_work_control');

  describe("validateMetadata", function() {
    var mockCheckbox = {
      check: function() { },
      uncheck: function() { },
    };

    beforeEach(function() {
      var fixture = setFixtures('<form id="edit_generic_work">' +
        '<aside id="form-progress"><ul><li id="required-metadata"><li id="required-files"></ul>' +
        '<input type="checkbox" name="agreement" id="agreement" value="1" required="required" checked="checked" />' +
        '<input type="submit"></aside></form>');
      target = new control.SaveWorkControl(fixture.find('#form-progress'));
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

  describe("validateAgreement", function() {
    var target;
    beforeEach(function() {
      var fixture = setFixtures('<form id="edit_generic_work">' +
        '<aside id="form-progress"><ul><li id="required-metadata"><li id="required-files"></ul>' +
        '<input type="checkbox" name="agreement" id="agreement" value="1" required="required" checked="checked" />' +
        '<input type="submit"></aside></form>');
      target = new control.SaveWorkControl(fixture.find('#form-progress'));
      target.activate()
    });
    it("forces user to agree if new files are added", function() {
      // Agreement starts as accepted...
      target.uploads = { hasNewFiles: false };
      expect(target.validateAgreement(true)).toEqual(true);

      // ...and becomes not accepted as soon as the user adds new files...
      target.uploads = { hasNewFiles: true };
      expect(target.validateAgreement(true)).toEqual(false);

      // ...but allows the user to manually agree again.
      target.depositAgreement.setAccepted();
      expect(target.validateAgreement(true)).toEqual(true);
    });
  });

  describe("validateFiles", function() {
    var mockCheckbox = {
      check: function() { },
      uncheck: function() { },
    };
    var form_id = 'new_generic_work';

    var buildTarget = function(form_id) {
      var buildFixture = function(id) {
        return setFixtures('<form id="' + id + '">' +
        '<aside id="form-progress"><ul><li id="required-metadata"><li id="required-files"></ul>' +
        '<input type="checkbox" name="agreement" id="agreement" value="1" required="required" checked="checked" />' +
        '<input type="submit"></aside></form>')
      }
      target = new control.SaveWorkControl(buildFixture(form_id).find('#form-progress'));
      target.requiredFiles = mockCheckbox;
      return target
    }

    beforeEach(function() {
      spyOn(mockCheckbox, 'check').and.stub();
      spyOn(mockCheckbox, 'uncheck').and.stub();
    });

    describe("when required files are present", function() {
      beforeEach(function() {
        target = buildTarget(form_id)
        target.uploads = {
          hasFiles: true,
          hasFileRequirement: true
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
        target = buildTarget(form_id)
        target.uploads = {
          hasFiles: false,
          hasFileRequirement: true
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
        target = buildTarget(form_id)
      });
      it("is complete", function() {
        target.validateFiles();
        expect(mockCheckbox.uncheck.calls.count()).toEqual(0);
        expect(mockCheckbox.check.calls.count()).toEqual(1);
      });
    });
  });

  describe("activate", function() {
    var target;
    beforeEach(function() {
      var fixture = setFixtures('<form id="new_generic_work"><aside id="form-progress"><ul><li id="required-metadata"><li id="required-files"></ul><input type="submit"></aside></form>');
      target = new control.SaveWorkControl(fixture.find('#form-progress'));
      target.activate()
    });

    it("is complete", function() {
      expect(target.requiredFields).toBeDefined();
      expect(target.uploads).toBeDefined();
      expect(target.depositAgreement).toBeDefined();
      expect(target.requiredMetadata).toBeDefined();
      expect(target.requiredFiles).toBeDefined();
      expect(target.saveButton).toBeDisabled();
    });

  });

  describe("on submit", function() {
    var target;
    beforeEach(function() {
      var fixture = setFixtures('<form id="new_generic_work"><aside id="form-progress"><ul><li id="required-metadata"><li id="required-files"></ul><input type="submit"></aside></form>');
      target = new control.SaveWorkControl(fixture.find('#form-progress'));
      target.activate()
    });

    describe("when the form is invalid", function() {
      it("prevents submission", function() {
        var spyEvent = spyOnEvent('#new_generic_work', 'submit');
        $('#new_generic_work').submit();
        expect(spyEvent).toHaveBeenPrevented();
      });
    });

    describe("when the form is valid", function() {
      it("prevents submission", function() {
        var spyEvent = spyOnEvent('#new_generic_work', 'submit');
        spyOn(target, 'isValid').and.returnValue(true);
        $('#new_generic_work').submit();
        expect(spyEvent).not.toHaveBeenPrevented();
      });
    });
  });
});
