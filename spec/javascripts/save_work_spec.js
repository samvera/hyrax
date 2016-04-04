describe("A suite", function() {
  var callback;
  var requiredBlankElements = [];
  var classes;
  var control = require('sufia/save_work/save_work_control');

  beforeEach(function() {
    requiredMetadataCheckbox = {
      removeClass: function () {},
      addClass: function(klass) { classes = klass }
    };
    requiredFields = { change: function(cb) { callback = cb; },
                       filter: function() { return requiredBlankElements; }
                     };
    form = { find: function() { return requiredFields; } }
    element = { closest: function() { return form; },
                find: function() { return requiredMetadataCheckbox; }
              };
  });

  describe("when none of the required fields are blank", function() {
    it("is complete", function() {
      requiredBlankElements = [];
      target = new control.SaveWorkControl(element);
      expect(classes).toEqual('complete');
    });
  });

  describe("when a required fields is blank", function() {
    it("is incomplete", function() {
      requiredBlankElements = [true];
      target = new control.SaveWorkControl(element);
      expect(classes).toEqual('incomplete');
    });
  });
});


