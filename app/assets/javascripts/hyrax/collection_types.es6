import CollectionUtilities from 'hyrax/collections_utils';

export default class CollectionTypes {
  constructor(element) {
    this.collectionUtilities = new CollectionUtilities();

    if (element.length > 0) {
      this.handleCollapseToggle();
      this.handleDelete();

      // Edit Collection Type
      this.setupAddParticipantsHandler();
      this.participantsAddButtonDisabler();
    }
  }

  setupAddParticipantsHandler() {
    const { addParticipants } = this.collectionUtilities;
    const wrapEl = '.form-add-participants-wrapper';
    const url = '/admin/collection_type_participants?locale=en';

    $('#participants')
      .find('.add-participants-form input[type="submit"]')
      .on(
        'click',
        {
          wrapEl,
          // This is a callback (seems odd here because just passing in a string value),
          // because other urls need to be calculated with an id or other param only truly
          // known from when we know the clicked element's place in DOM.
          urlFn: e => url
        },
        addParticipants.handleAddParticipants.bind(addParticipants)
      );
  }

  handleCollapseToggle() {
    let $collapseHeader = $('a.collapse-header');
    let $collapseHeaderSpan = $('a.collapse-header').find('span');
    const collapseText = $collapseHeader.data('collapseText');
    const expandText = $collapseHeader.data('expandText');

    // Toggle show/hide of collapsible content on bootstrap toggle events
    $('#collapseAbout').on('show.bs.collapse', () => {
      $collapseHeader.addClass('open');
      $collapseHeaderSpan.html(collapseText);
    });
    $('#collapseAbout').on('hide.bs.collapse', () => {
      $collapseHeader.removeClass('open');
      $collapseHeaderSpan.html(expandText);
    });
  }

  handleDelete() {
    let trData = null;

    // Click delete collections type button in the table row
    $('.delete-collection-type').on('click', event => {
      let dataset = event.target.dataset;
      let collectionType = JSON.parse(dataset.collectionType) || null;
      let hasCollections = dataset.hasCollections === 'true';
      this.handleDelete_event_target = event.target;
      this.collectionType_id = collectionType.id;

      if (hasCollections === true) {
        $('.view-collections-of-this-type').attr(
          'href',
          dataset.collectionTypeIndex
        );
        $('#deleteDenyModal').modal();
      } else {
        $('#deleteModal').modal();
      }
    });

    // Confirm delete collection type
    $('.confirm-delete-collection-type').on('click', event => {
      event.preventDefault();
      $.ajax({
        url: window.location.pathname + '/' + this.collectionType_id,
        type: 'DELETE',
        done: function(e) {
          $(this.handleDelete_event_target)
            .parent('td')
            .parent('tr')
            .remove();
          let defaultButton = $(event.target)
            .parent('div')
            .find('.btn-secondary');
          defaultButton.trigger('click');
        }
      });
    });

    // Confirm delete collection type
    $('.view-collections-of-this-type').on('click', event => {
      $('#deleteDenyModal').modal('hide');
    });
  }

  /**
   * Set up enabling/disabling "Add" button for adding groups and/or users in
   * Edit Collection Type > Participants tab
   * @return {void}
   */
  participantsAddButtonDisabler() {
    const { addParticipantsInputValidator } = this.collectionUtilities;
    // Selector for the button to enable/disable
    const buttonSelector = '.add-participants-form input[type="submit"]';
    const inputsWrapper = '.form-add-participants-wrapper';

    $('#participants')
      .find(inputsWrapper)
      .on(
        'change',
        // custom data we need passed into the event handler
        {
          buttonSelector,
          inputsWrapper
        },
        addParticipantsInputValidator.handleWrapperContentsChange.bind(
          addParticipantsInputValidator
        )
      );
  }
}
