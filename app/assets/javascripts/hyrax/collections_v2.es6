import CollectionUtilities from 'hyrax/collections_utils';

export default class CollectionsV2 {
  constructor() {
    this.collectionUtilities = new CollectionUtilities();
    this.setupAddSharingHandler();
    this.sharingAddButtonDisabler();
  }

  /**
   * Set up the handler for adding groups or users via AJAX POSTS at the following location:
   * Collection > Edit > Sharing tab; or
   * Collection Types > Edit > Participants tab
   * @return {void}
   */
  setupAddSharingHandler() {
    const { addParticipants } = this.collectionUtilities;
    const wrapEl = '.form-add-sharing-wrapper';

    $('#participants')
      .find('.edit-collection-add-sharing-button')
      .on('click', {
        wrapEl,
        urlFn: (e) => {
          const $wrapEl = $(e.target).parents(wrapEl);
          return '/dashboard/collections/' + $wrapEl.data('id') + '/permission_template?locale=en';
        }
      },
      addParticipants.handleAddParticipants.bind(addParticipants));
  }

  /**
   * Set up enabling/disabling "Add" button for adding groups and/or users in
   * Edit Collection > Sharing tab
   * @return {void}
   */
  sharingAddButtonDisabler() {
    const { addParticipantsInputValidator } = this.collectionUtilities;
    // Selector for the button to enable/disable
    const buttonSelector = '.edit-collection-add-sharing-button';
    const inputsWrapper = '.form-add-sharing-wrapper';

    $('#participants')
      .find(inputsWrapper)
      .on(
        'change',
        // custom data we need passed into the event handler
        {
          buttonSelector: '.edit-collection-add-sharing-button',
          inputsWrapper
        },
        addParticipantsInputValidator.handleWrapperContentsChange.bind(
          addParticipantsInputValidator
        )
      );
  }
}
