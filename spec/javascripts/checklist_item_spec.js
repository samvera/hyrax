describe("ChecklistItem", function() {
  var control = require('hyrax/save_work/checklist_item');
  var target, element = null;

  beforeEach(function() {
    element = $('<li class="incomplete"/>');
    target = new control.ChecklistItem(element);
  });

  describe("check", function() {
    it("is complete", function() {
      target.check();
      expect(element.attr('class')).toEqual('complete');
    });
  });

  describe("uncheck", function() {
    it("is incomplete", function() {
      target.uncheck();
      expect(element.attr('class')).toEqual('incomplete');
    });
  });
});
