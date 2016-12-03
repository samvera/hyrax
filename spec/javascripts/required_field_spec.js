describe('RequiredFields', function() {
  var control = require('hyrax/save_work/required_fields');
  var target = null;

  describe('areComplete', function() {
    describe('when required metadata is not present' ,  function() {
      beforeEach(function() {
        var fixture = setFixtures(form('',''));
        target = new control.RequiredFields(fixture.find('#new_generic_work'),function () {});
      });
      it('is not complete', function() {
        expect(target.areComplete).toEqual(false);
      });
    });

    describe('when required metadata is not present', function() {
      beforeEach(function() {
        var fixture = setFixtures(form('title','selected="selected"'));
        target = new control.RequiredFields(fixture.find('#new_generic_work'),function () {});
      });
      it('is complete', function() {
        expect(target.areComplete).toEqual(true);
      });
    });

  });
});

function form(title, resourceTypeSelected) {
    return '<form id="new_generic_work">' +
        '  <div>' +
        '    <input class="string multi_value required form-control generic_work_title form-control multi-text-field" required="required" aria-required="true" name="generic_work[title][]" value="' + title + '" id="generic_work_title" type="text">' +
        '  </div>' +
        '  <div>' +
        '    <select class="form-control select required form-control" multiple="multiple" required="required" aria-required="true" name="generic_work[resource_type][]" id="generic_work_resource_type">' +
        '      <option value="Article"' + resourceTypeSelected + '>Article</option>' +
        '      <option value="Other">Other</option>' +
        '    </select>' +
        '  </div>' +
        '</form>';
}
