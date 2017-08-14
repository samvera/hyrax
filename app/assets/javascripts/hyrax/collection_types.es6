export default class CollectionTypes {

  constructor(element) {
    if (element.length > 0) {
      this.handleCollapseToggle()
      this.handleDelete()
    }
  }

  handleCollapseToggle() {
    let $collapseHeader = $('a.collapse-header')
    let $collapseHeaderSpan = $('a.collapse-header').find('span')

    // Toggle show/hide of collapsible content on bootstrap toggle events
    $('#collapseAbout').on('show.bs.collapse', () => {
      $collapseHeader.addClass('open')
      $collapseHeaderSpan.html('Less')
    })
    $('#collapseAbout').on('hide.bs.collapse', () => {
      $collapseHeader.removeClass('open')
      $collapseHeaderSpan.html('More')
    })
  }

  handleDelete() {
    let trData = null

    // Click delete collections type button in the table row
    $('.delete-collection-type').on('click', (event) => {
      let dataset = event.target.dataset
      let collectionType = JSON.parse(dataset.collectionType) || null
      let hasCollections = dataset.hasCollections === 'true'

      if (hasCollections === true) {
        $('#deleteDenyModal').modal()
      } else {
        $('#deleteModal').modal()
      }
    })

    // Confirm delete collection type
    $('.confirm-delete-collection-type').on('click', (event) => {
      // TODO: Handle the delete functionality here
    })
  }

}
