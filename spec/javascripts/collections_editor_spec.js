describe('thumbnail select', () => {
  var CollectionEditor = require('hyrax/collections/editor')

  var editor;
  beforeEach(() =>  {
    setFixtures(`
        <form class='editor'>
        <input type="text" id="collection_thumbnail_id autocomplete="off">
        <input type="text" id="participants">
        </form>
        `)
    editor = new CollectionEditor($('form'))
    spyOn(editor, "pathname").and.returnValue("/dashboard/collections/edith-stein-collection/edit");
  })



  it('should change the thumbnail select url for auto complete', () => {
    expect(editor.url()).toEqual('/dashboard/collections/edith-stein-collection/files')
  })
})