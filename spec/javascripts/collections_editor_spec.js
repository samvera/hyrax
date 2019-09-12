describe('thumbnail select', () => {
  var CollectionEditor = require('hyrax/collections/editor')
  var localContext = {
    "window":{
      location:{
        href: "http://example.com/dashboard/collections/edith-stein-collection/edit?_=1566882335253"
      }
    }
  }

  var editor;
  beforeEach(() =>  {
    setFixtures(`
        <form class='editor'>
        <input type="text" id="collection_thumbnail_id autocomplete="off">
        <input type="text" id="participants">
        </form>
        `)
    editor = new CollectionEditor($('form'))
  })



  it('should change the thumbnail select url for auto complete', () => {
    with(localContext){
	    expect(editor.url()).toEqual('/dashboard/collections/edith-stein-collection/files?_=1566882335253')
    }
  })
})
