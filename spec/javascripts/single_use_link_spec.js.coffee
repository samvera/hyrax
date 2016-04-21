describe "single use link", ->

    beforeEach ->
      # setup two inputs for us to attach  auto complete to
      setFixtures  '<a id="test_link" data-generate-single-use-link-url="/single_use_link/generate_show/abc123" />'

    # call ajax to get a link
    it "calls for the expected link", ->
      # set up mock and response
      resp = responseText: "/single_use_linkabc123"
      options = {
                  type: 'post'
                  url: "/single_use_link/generate_show/abc123"
                }
      se = spyOn($, "ajax").and.returnValue resp

      # get the single use link
      var result
      getSingleUse $('#test_link'), function(data) { result = data }

      #verify the result
      expect(result).toEqual "#{window.location.protocol}//#{window.location.host}/single_use_linkabc123"

      # verify the options sent to the ajax call
      expect(se).toHaveBeenCalledWith(options)
