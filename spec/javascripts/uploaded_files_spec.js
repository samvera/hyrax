describe("UploadedFiles", function() {
  var control = require('sufia/save_work/uploaded_files');

  describe("hasFileRequirement", function() {
    describe("with required file element", function() {
      it("returns true", function() {
        var fixture = setFixtures('<form><ul class="requirements"><li class="incomplete" id="required-files">Add files</li></ul></form>');
        var element = fixture.find('form');
        target = new control.UploadedFiles(element);
        expect(target.hasFileRequirement).toBe(true);
      });
    });

    describe("without required file element", function() {
      it("returns false", function() {
        var fixture = setFixtures('<form><ul class="requirements"><li>Not files</li></ul></form>');
        var element = fixture.find('form');
        target = new control.UploadedFiles(element);
        expect(target.hasFileRequirement).toBe(false);
      });
    });
  });
});
