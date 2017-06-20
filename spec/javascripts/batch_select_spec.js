var BatchSelect = require('hyrax/batch_select');

describe("BatchSelect", function() {
  beforeEach(function() {
    loadFixtures('dashboard_batch_forms.html');
    BatchSelect.initialize_batch_selected();
  });

  describe("Find checked boxes", function() {
    it("returns true", function() {
      $('#edit').click();
      expect($('input[type=hidden]')).toHaveValue('kh04dp681')
    });
  });
});
