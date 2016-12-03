describe "FileManagerSorting", ->
  sortm = require('hyrax/file_manager/sorting')
  sort_manager = null
  save_manager = null
  titles = null
  beforeEach () ->
    loadFixtures('sortable.html')
    save_manager = {
      push_changed: () -> {},
      mark_unchanged: () -> {}
    }
    sort_manager= new sortm(save_manager)
  describe "sort_alpha", ->
    it "sorts correctly, ignoring capitalization", ->
      expect(sort_manager.order).toEqual(sort_manager.element.data("current-order"))
      sort_manager.sort_alpha()
      # order has changed
      expect(sort_manager.order).not.toEqual(sort_manager.element.data("current-order"))
      # order is now alphabetical
      titles = $("input.title").map( ->
        return $(@).val() 
      ).get()
      expect(titles).toEqual([ 'child1', 'child2', 'CIMG1815.JPG', 'CIMG1816 copy.JPG', 'zeldogbeach2.jpg' ])
