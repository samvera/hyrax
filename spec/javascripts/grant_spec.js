describe("Grant", function() {
  var person = require('hyrax/permissions/person');
  var pkg = require('hyrax/permissions/grant');
  var target

  beforeEach(function() {
    var agent = new person.Person('Hannah');
    target = new pkg.Grant(agent, 'read', 'View/Download');
  });

  describe("name", function() {
    it("is delegates name to agent", function() {
      expect(target.name).toEqual('Hannah');
    });
  });

  describe("type", function() {
    it("is delegates type to agent", function() {
      expect(target.type).toEqual('person');
    });
  });

  describe("access", function() {
    it("is has access", function() {
      expect(target.access).toEqual('read');
    });
  });

  describe("accessLabel", function() {
    it("is has accessLabel", function() {
      expect(target.accessLabel).toEqual('View/Download');
    });
  });

  describe("index", function() {
    it("is has index", function() {
      expect(target.index).toEqual(0);
      target.index = 2
      expect(target.index).toEqual(2);
    });
  });
});

