describe "Single Use Links manager", ->
  sul_manager = null
  beforeEach () ->
    loadFixtures('sul_table.html')
    sul_manager = $.fn.singleUseLinks()
    jasmine.Ajax.install()
  afterEach () ->
    jasmine.Ajax.uninstall()  

  describe "#reload_table", ->
    request = null

    it "replaces the table's content with html data", ->
      jasmine.Ajax.stubRequest('/single_use_link/generated/fs-id').andReturn({
        "status": 200, 
        "contentType": 'text/plain',
        "responseText": 'updated table contents'
      });

      sul_manager.reload_table()
      request = jasmine.Ajax.requests.mostRecent()
      expect(request.responseText).toEqual("updated table contents")

  describe "#create_link", ->
    request = null

    it "requests a new link", ->
      jasmine.Ajax.stubRequest('/single_use_link/generate/fs-id').andReturn({
        "status": 200, 
        "contentType": 'text/plain',
        "responseText": 'created a link'
      });

      sul_manager.create_link($('.generate-single-use-link'))
      request = jasmine.Ajax.requests.mostRecent()
      expect(request.responseText).toEqual("created a link")

  describe "#delete_link", ->
    request = null

    it "removes the link from the table", ->
      jasmine.Ajax.stubRequest('/single_use_link/fs-id/delete/key').andReturn({
        "status": 200, 
        "contentType": 'text/plain',
        "responseText": 'deleted a link'
      });

      sul_manager.delete_link($('.delete-single-use-link'))
      request = jasmine.Ajax.requests.mostRecent()
      expect(request.responseText).toEqual("deleted a link")
      expect($("table.single-use-links tbody").html).not.toContain("<tr>")
