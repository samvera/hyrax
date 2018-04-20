export default class CollectionTypes {

  constructor(element) {
    if (element.length > 0) {
      this.handleCollapseToggle()
      this.handleDelete()

      // Edit Collection Type
      this.handleAddParticipants()
    }
  }

  handleAddParticipants() {
    $('#participants').find('.add-participants-form input[type="submit"]').on('click', function(e) {
      e.preventDefault();
      const $wrapEl = $(e.target).parents('.form-add-participants-wrapper');
      if ($wrapEl.length === 0) {
        return;
      }
      const serialized = $wrapEl.find(':input').serialize();
      const url = '/admin/collection_type_participants?locale=en';
      if (serialized.length === 0) {
        return;
      }

      $.ajax({
        type: 'POST',
        url: url,
        data: serialized
      }).done(function(response) {
        // Success handler here, possibly show alert success if page didn't reload?
      }).fail(function(err) {
        console.error(err);
      });

    });
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
