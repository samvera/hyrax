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
      this.handleDelete_event_target = event.target;
      this.collectionType_id = collectionType.id;

      if (hasCollections === true) {
        $('.view-collections-of-this-type').attr('href',dataset.collectionTypeIndex)
        $('#deleteDenyModal').modal()
      } else {
        $('#deleteModal').modal()
      }
    })

    // Confirm delete collection type
    $('.confirm-delete-collection-type').on('click', (event) => {
        event.preventDefault();
        $.ajax({
            url: window.location.pathname + '/' + this.collectionType_id,
            type: 'DELETE',
            done: function(e) {
                $(this.handleDelete_event_target).parent('td').parent('tr').remove();
                let defaultButton = $(event.target).parent('div').find('.btn-default');
                defaultButton.trigger( 'click' );
            }
        })
    })

    // Confirm delete collection type
    $('.view-collections-of-this-type').on('click', (event) => {
        $('#deleteDenyModal').modal('hide')
    })

  }

}
