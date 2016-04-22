describe "single use link", ->

    beforeEach ->
      # setup two inputs for us to attach  auto complete to
      setFixtures  '<a id="test_link" data-generate-single-use-link-url="/single_use_link/generate_show/abc123" />'
      jasmine.Ajax.install();

    # call ajax to get a link
    it "calls for the expected link", ->
      onSuccess = jasmine.createSpy('onSuccess')
      # get the single use link
      getSingleUse $('#test_link'), onSuccess

      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith(TestResponses.single_use_link.success)


      # verify the correct request was made
      expect(request.url).toBe('/single_use_link/generate_show/abc123')
      expect(request.method).toBe('POST')
      expect(onSuccess).toHaveBeenCalledWith('http://test.host/single_use_linkabc123')
